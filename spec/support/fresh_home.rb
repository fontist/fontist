RSpec.shared_context "fresh home" do
  attr_reader :temp_dir

  around do |example|
    retry_count = 0
    begin
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run

        @temp_dir = nil

        # On Windows, wait a bit for file handles to be released
        sleep(0.1) if Fontist::Utils::System.user_os == :windows
      end
    rescue Errno::ENOTEMPTY, Errno::EACCES => e
      # Windows-specific: retry cleanup after file handles are released
      if Fontist::Utils::System.user_os == :windows && retry_count < 3
        retry_count += 1
        sleep(0.2)
        retry
      end
      # If cleanup still fails, warn but don't fail the test
      warn "Warning: Could not clean up temp directory: #{e.message}"
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

    FileUtils.mkdir_p(Fontist.fonts_path)
    FileUtils.mkdir_p(Fontist.formulas_path)

    # Remove config file to prevent state pollution from previous tests
    File.delete(Fontist.config_path) if File.exist?(Fontist.config_path)

    # CRITICAL: Delete system index file to prevent state pollution from
    # previous tests that might have installed fonts to the system location
    system_index_path = Fontist.system_index_path
    File.delete(system_index_path) if File.exist?(system_index_path)

    # CRITICAL: Save the formula index paths NOW while the stub is active.
    # We need to delete these specific files in the after hook, because
    # after we remove the stub, Fontist.formula_index_path will return
    # a different path (the normal ~/.fontist path).
    @formula_index_path = Fontist.formula_index_path.to_s
    @formula_preferred_family_index_path = Fontist.formula_preferred_family_index_path.to_s
    @formula_filename_index_path = Fontist.formula_filename_index_path.to_s

    Fontist::Config.reset
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::SystemFont.disable_find_styles_cache # Reset find_styles cache
    Fontist::Indexes::FontistIndex.reset_cache
    Fontist::Indexes::UserIndex.reset_cache
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
end
