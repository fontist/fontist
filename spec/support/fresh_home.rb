RSpec.shared_context "fresh home" do
  attr_reader :temp_dir

  around do |example|
    Dir.mktmpdir do |dir|
      @temp_dir = dir
      example.run

      @temp_dir = nil
    end
  rescue Errno::ENOTEMPTY, Errno::EACCES => e
    # Windows-specific: Don't retry, just warn
    #
    # We intentionally DON'T retry on Windows because:
    # 1. Re-running the test in a new temp directory causes state leakage
    # 2. Tests that check file existence would fail (file created in dir A, checked in dir B)
    # 3. The retry mechanism creates unpredictable test results
    #
    # Instead, we accept that temp directories may accumulate on Windows.
    # This is acceptable because:
    # - They're in the system temp directory
    # - They get cleaned up on system reboot
    # - CI environments are ephemeral anyway
    if Fontist::Utils::System.user_os == :windows
      warn "Warning: Could not clean up temp directory (Windows file locking): #{e.message}"
      warn "Temp directory may accumulate: #{Dir.glob(File.join(Dir.tmpdir,
                                                                'tmp*')).count} temp dirs present"
    else
      # On Unix, retry a few times as this is usually transient
      retry_count = 0
      begin
        retry_count += 1
        sleep(0.5)
        retry
      rescue StandardError
        warn "Warning: Could not clean up temp directory: #{e.message}"
      end
    end
  end

  before do
    # Reset formulas_path to ensure isolation per test
    @orig_formulas_path = Fontist.formulas_path
    Fontist.formulas_path = nil

    allow(Fontist).to receive(:default_fontist_path)
      .and_return(Pathname.new(temp_dir))

    # Stub user and system font paths via ENV to temp directories
    @orig_user_path = ENV["FONTIST_USER_FONTS_PATH"]
    @orig_system_path = ENV["FONTIST_SYSTEM_FONTS_PATH"]

    user_fonts_temp = File.join(temp_dir, "user_fonts")
    system_fonts_temp = File.join(temp_dir, "system_fonts")

    FileUtils.mkdir_p(user_fonts_temp)
    FileUtils.mkdir_p(system_fonts_temp)

    ENV["FONTIST_USER_FONTS_PATH"] = user_fonts_temp
    ENV["FONTIST_SYSTEM_FONTS_PATH"] = system_fonts_temp

    # CRITICAL: Explicitly reset any stubs that might have been set by previous tests
    # This ensures "fresh home" always starts with a clean slate, even after
    # "system fonts" or other contexts that modify Fontist::SystemFont behavior
    allow(Fontist::SystemFont).to receive(:system_config).and_call_original
    allow(Fontist::SystemFont).to receive(:system_font_paths).and_call_original
    allow(Fontist).to receive(:system_file_path).and_call_original

    stub_system_fonts

    FileUtils.mkdir_p(Fontist.formulas_path)

    # CRITICAL: Reset caches first to ensure all index files are closed
    # This is especially important on Windows where file locking can prevent deletion
    Fontist::Config.reset
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::SystemFont.disable_find_styles_cache # Reset find_styles cache
    Fontist::Indexes::FontistIndex.reset_cache
    Fontist::Indexes::UserIndex.reset_cache
    Fontist::Indexes::SystemIndex.reset_cache

    # CRITICAL: Delete formula index files BEFORE running the test to ensure
    # each test starts with a clean index state. This prevents stale index data
    # from previous test runs from interfering. The FilenameIndex stores paths
    # relative to Fontist.formulas_path, which changes in fresh_home context.
    # On Windows, use retries to handle file locking issues.
    delete_with_retry(Fontist.formula_index_path.to_s)
    delete_with_retry(Fontist.formula_preferred_family_index_path.to_s)
    delete_with_retry(Fontist.formula_filename_index_path.to_s)

    # Remove config file to prevent state pollution from previous tests
    delete_with_retry(Fontist.config_path.to_s)

    # CRITICAL: Delete system index file to prevent state pollution from
    # previous tests that might have installed fonts to the system location
    delete_with_retry(Fontist.system_index_path.to_s)

    # CRITICAL: Save the formula index paths NOW while the stub is active.
    # We need to delete these specific files in the after hook, because
    # after we remove the stub, Fontist.formula_index_path will return
    # a different path (the normal ~/.fontist path).
    @formula_index_path = Fontist.formula_index_path.to_s
    @formula_preferred_family_index_path = Fontist.formula_preferred_family_index_path.to_s
    @formula_filename_index_path = Fontist.formula_filename_index_path.to_s

    # Stub system fonts after all cleanup is done
  end

  after do
    # Restore original formulas_path to nil so it defaults correctly
    # DO NOT restore @orig_formulas_path because it was saved after the stub
    # was applied, so it points to a temp directory that no longer exists.
    # By setting to nil, it will resolve based on the (now restored) default_fontist_path
    Fontist.formulas_path = nil

    # Restore original ENV values
    ENV["FONTIST_USER_FONTS_PATH"] = @orig_user_path
    ENV["FONTIST_SYSTEM_FONTS_PATH"] = @orig_system_path

    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::SystemFont.disable_find_styles_cache # Reset find_styles cache
    Fontist::Indexes::FontistIndex.reset_cache
    Fontist::Indexes::UserIndex.reset_cache
    Fontist::Indexes::SystemIndex.reset_cache

    # CRITICAL: Delete formula index files using the paths saved in before hook.
    # We must use the saved paths because the stub is still active here.
    # The index files contain formula paths relative to the temp directory that
    # no longer exists after fresh_home teardown. Deleting them forces a rebuild
    # with the correct formulas_path in subsequent tests.
    # NOTE: The default_fontist_path stub is reset by spec_helper's after(:each) hook
    File.delete(@formula_index_path) if @formula_index_path && File.exist?(@formula_index_path)
    File.delete(@formula_preferred_family_index_path) if @formula_preferred_family_index_path && File.exist?(@formula_preferred_family_index_path)
    File.delete(@formula_filename_index_path) if @formula_filename_index_path && File.exist?(@formula_filename_index_path)
  end

  # Helper method to delete a file with retries for Windows file locking
  #
  # @param path [String, nil] The file path to delete
  # @param max_retries [Integer] Maximum number of retry attempts
  # @param retry_delay [Float] Delay in seconds between retries
  def delete_with_retry(path, max_retries: 3, retry_delay: 0.2)
    return if path.nil? || path.empty?
    return unless File.exist?(path)

    retry_count = 0
    begin
      File.delete(path)
    rescue Errno::EACCES, Errno::ENOENT => e
      retry_count += 1
      if retry_count < max_retries
        sleep(retry_delay)
        retry
      end

      # Log warning but don't fail - this is cleanup code
      warn "Warning: Could not delete file after #{max_retries} attempts: #{path} (#{e.class}: #{e.message})"
    end
  end
end
