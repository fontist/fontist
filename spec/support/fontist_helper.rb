module Fontist
  module Helper
    # Reset all Fontist caches to ensure test isolation
    # Delegates to IsolationManager for proper encapsulation
    def reset_all_fontist_caches
      Fontist::Test::IsolationManager.instance.reset_all
    end

    # Reset verification flags on cached index instances
    # This is now handled by IsolationManager components
    def reset_index_verification_flags
      # Deprecated - handled by IsolationManager
      reset_all_fontist_caches
    end

    def stub_fontist_path_to_temp_path
      allow(Fontist).to receive(:fontist_path).and_return(
        Fontist.root_path.join("spec", "fixtures"),
      )
    end

    def fresh_fonts_and_formulas
      fresh_fontist_home do
        stub_system_fonts

        FileUtils.mkdir_p(Fontist.fonts_path)
        FileUtils.mkdir_p(Fontist.formulas_path)

        yield

        # Comprehensive cleanup for test isolation
        Fontist::Index.reset_cache
        Fontist::SystemIndex.reset_cache
        Fontist::SystemFont.reset_font_paths_cache
        Fontist::Config.reset # Reset config singleton to ensure test isolation

        # Reset new OOP index singletons
        Fontist::Indexes::FontistIndex.reset_cache
        Fontist::Indexes::UserIndex.reset_cache
        Fontist::Indexes::SystemIndex.reset_cache

        # Reset interactive mode to default
        Fontist.interactive = false
      end
    end

    def fresh_fontist_home
      retry_count = 0
      begin
        Dir.mktmpdir do |dir|
          Fontist.default_fontist_path
          Fontist.formulas_path
          Fontist.formulas_path = nil

          allow(Fontist).to receive(:default_fontist_path)
            .and_return(Pathname.new(dir))

          # Stub user and system font paths via ENV to prevent accessing real directories
          # This ensures UserIndex and SystemIndex scan only temp directories
          user_fonts_temp = File.join(dir, "user_fonts")
          system_fonts_temp = File.join(dir, "system_fonts")

          FileUtils.mkdir_p(user_fonts_temp)
          FileUtils.mkdir_p(system_fonts_temp)

          orig_user_path = ENV["FONTIST_USER_FONTS_PATH"]
          orig_system_path = ENV["FONTIST_SYSTEM_FONTS_PATH"]

          ENV["FONTIST_USER_FONTS_PATH"] = user_fonts_temp
          ENV["FONTIST_SYSTEM_FONTS_PATH"] = system_fonts_temp

          # CRITICAL: Save the formula index paths NOW while the stub is active.
          # We need to delete these specific files in the cleanup section.
          formula_index_path = Fontist.formula_index_path.to_s
          formula_preferred_family_index_path = Fontist.formula_preferred_family_index_path.to_s
          formula_filename_index_path = Fontist.formula_filename_index_path.to_s

          # CRITICAL: Delete existing index files BEFORE running the test to ensure
          # each test starts with a clean index state. This prevents stale index data
          # from previous test runs from interfering. The FilenameIndex stores paths
          # relative to Fontist.formulas_path, which changes in fresh_home context.
          # On Windows, use retries to handle file locking issues.
          delete_with_retry(formula_index_path)
          delete_with_retry(formula_preferred_family_index_path)
          delete_with_retry(formula_filename_index_path)

          yield dir

          # Restore original values
          # NOTE: Do NOT restore orig_formulas_path - it was saved after the stub
          # was applied, so it points to a temp directory. Set to nil instead
          # so it defaults based on the (now restored) default_fontist_path.
          Fontist.formulas_path = nil
          ENV["FONTIST_USER_FONTS_PATH"] = orig_user_path
          ENV["FONTIST_SYSTEM_FONTS_PATH"] = orig_system_path

          # CRITICAL: Delete formula index files using the paths saved above.
          # We must use the saved paths because the stub is still active here.
          # The index files contain formula paths relative to the temp directory.
          # NOTE: The default_fontist_path stub is reset by spec_helper's after(:each) hook
          File.delete(formula_index_path) if formula_index_path && File.exist?(formula_index_path)
          File.delete(formula_preferred_family_index_path) if formula_preferred_family_index_path && File.exist?(formula_preferred_family_index_path)
          File.delete(formula_filename_index_path) if formula_filename_index_path && File.exist?(formula_filename_index_path)

          reset_all_fontist_caches # Clean up after

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

    def fresh_main_repo(branch = "main")
      remote_main_repo(branch) do |dir|
        # Remove existing formulas directory if it exists to avoid Git clone errors
        if Dir.exist?(Fontist.formulas_repo_path)
          Fontist::Utils::FileOps.safe_rm_rf(Fontist.formulas_repo_path)
        end

        Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

        yield dir
      end
    end

    def remote_main_repo(branch = "main")
      Dir.mktmpdir do |dir|
        FileUtils.mkdir(File.join(dir, "Formulas"))
        FileUtils.touch(File.join(dir, "Formulas", ".keep"))

        init_repo(dir, branch) do |git|
          git.add(File.join("Formulas", ".keep"))
        end

        yield dir
      end
    end

    def init_repo(dir, branch)
      git = Git.init(dir)
      git.checkout(branch, new_branch: true)
      git.config("user.name", "Test")
      git.config("user.email", "test@example.com")

      yield git

      git.commit("msg")
    end

    def no_fonts_and_formulas(&block)
      no_fonts do
        no_formulas(&block)
      end
    end

    def no_fonts(&block)
      if block
        stub_fonts_path_to_new_path do
          stub_system_fonts_path_to_new_path(&block)
        end
      else
        stub_fonts_path_to_new_path
        stub_system_fonts_path_to_new_path
      end
    end

    def stub_fonts_path_to_new_path
      @fontist_dir = create_tmp_dir

      # Create a parent fontist directory structure for index files
      # This ensures fontist_index_path and related paths are writable
      @fontist_parent_dir = create_tmp_dir

      # Create formulas directory structure to satisfy check_index
      # formulas_repo_path = fontist_path/versions/v4/formulas/Formulas
      versions_dir = File.join(@fontist_parent_dir, "versions", "v4",
                               "formulas")
      FileUtils.mkdir_p(File.join(versions_dir, "Formulas"))

      # Stub fontist_path first (affects derived paths like fontist_index_path)
      allow(Fontist).to receive(:fontist_path)
        .and_return(Pathname.new(@fontist_parent_dir))

      # Then stub fonts_path to the separate fonts directory
      allow(Fontist).to receive(:fonts_path)
        .and_return(Pathname.new(@fontist_dir))

      return @fontist_dir unless block_given?

      result = yield @fontist_dir
      cleanup_fontist_fonts
      Fontist::SystemIndex.reset_cache
      Fontist::SystemFont.reset_font_paths_cache
      result
    end

    def stub_system_fonts_path_to_new_path
      @system_dir = create_tmp_dir

      @system_file_tempfile = Tempfile.new
      @system_file_tempfile.write(YAML.dump(system_paths(@system_dir)))
      @system_file_tempfile.close

      stub_system_fonts(@system_file_tempfile)

      return @system_dir unless block_given?

      result = yield @system_dir
      cleanup_system_fonts
      Fontist::SystemIndex.reset_cache
      Fontist::SystemFont.reset_font_paths_cache

      # Explicitly unlink tempfile on Windows to avoid permission errors
      if Fontist::Utils::System.user_os == :windows && @system_file_tempfile
        begin
          @system_file_tempfile.unlink
        rescue StandardError
          # Ignore cleanup errors
        end
        @system_file_tempfile = nil
      end

      result
    end

    def system_paths(path)
      pattern = File.join(path,
                          "**",
                          "*.{[t|T][t|T][f|F],[o|O][t|T][f|F],[t|T][t|T][c|C]}")
      paths = 4.times.map { { "paths" => [pattern] } } # rubocop:disable Performance/TimesMap, Layout/LineLength, avoid aliases in YAML
      { "system" => %w[linux windows macos unix].zip(paths).to_h }
    end

    def stub_system_fonts(system_file = nil)
      # If system_file is a Tempfile (or similar), use its path
      # This ensures YAML.load_file gets a path string, not an IO object
      path = system_file.respond_to?(:path) ? system_file.path : system_file

      allow(Fontist).to receive(:system_file_path).and_return(
        path || Fontist.root_path.join("spec", "fixtures", "system.yml"),
      )

      disable_system_font_paths_caching
    end

    def disable_system_font_paths_caching
      allow(SystemFont).to receive(:system_font_paths) do
        SystemFont.load_system_font_paths
      end
    end

    def cleanup_fonts
      cleanup_system_fonts
      cleanup_fontist_fonts
    end

    def cleanup_system_fonts
      raise("System dir is not stubbed") unless @system_dir

      Fontist::Utils::FileOps.safe_rm_rf(@system_dir)
      @system_dir = nil
    end

    def cleanup_fontist_fonts
      raise("Fontist dir is not stubbed") unless @fontist_dir

      Fontist::Utils::FileOps.safe_rm_rf(@fontist_dir)
      @fontist_dir = nil

      # Clean up parent fontist directory if it was created
      if @fontist_parent_dir
        Fontist::Utils::FileOps.safe_rm_rf(@fontist_parent_dir)
        @fontist_parent_dir = nil
      end
    end

    def stub_system_font_finder_to_fixture(name)
      allow(Fontist::SystemFont).to receive(:find)
        .and_return(["spec/fixtures/fonts/#{name}"])
    end

    def stub_system_font_to(name)
      allow(Fontist::SystemFont).to receive(:find).and_return([name])
    end

    def stub_license_agreement_prompt_with(confirmation = "yes")
      allow(Fontist.ui).to receive(:ask).and_return(confirmation)
    end

    def stub_license_agreement_prompt_with_exception
      allow(Thor::LineEditor).to receive(:readline).and_raise(Errno::EBADF)
    end

    def fixtures_dir(&block)
      Dir.chdir(Fontist.root_path.join("spec", "fixtures"), &block)
    end

    def stub_font_file(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      FileUtils.touch(File.join(dir, filename))
    end

    def font_files
      # Search recursively for font files in formula subdirectories
      Dir.glob(Fontist.fonts_path.join("**", "*"))
        .select { |f| File.file?(f) }
        .map { |f| File.basename(f) }
    end

    def font_file(filename)
      # Search recursively to support formula-keyed structure
      matches = Dir.glob(Fontist.fonts_path.join("**", filename))
      return Pathname.new(matches.first) if matches.any?

      # Fallback to flat path for backward compatibility
      Pathname.new(Fontist.fonts_path.join(filename))
    end

    def font_path(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      # Search recursively to support both flat and formula-keyed structures
      matches = Dir.glob(File.join(dir, "**", filename))
      return matches.first if matches.any?

      # Fallback to old flat path for backward compatibility
      File.join(dir, filename)
    end

    def formula_font_path(formula_key, filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      File.join(dir, formula_key, filename)
    end

    def system_font_path(filename)
      raise("System dir is not stubbed") unless @system_dir

      File.join(@system_dir, filename)
    end

    def fontist_font_path(filename)
      raise("Fontist dir is not stubbed") unless @fontist_dir

      File.join(@fontist_dir, filename)
    end

    def create_tmp_dir
      dir = Dir.mktmpdir
      Dir.glob(dir).first # expand the ~1 suffix on Windows
    end

    def example_font(filename)
      # Infer formula key from font filename
      # e.g., "overpass-regular.otf" → "overpass"
      # e.g., "texgyrechorus-mediumitalic.otf" → "tex_gyre_chorus"
      # e.g., "AndaleMo.TTF" → "andale" (needs special handling)
      # e.g., "Roboto-Regular.ttf" → "roboto"
      formula_key = infer_formula_key_from_filename(filename)

      # Create formula-keyed subdirectory
      target_dir = Fontist.fonts_path.join(formula_key)
      FileUtils.mkdir_p(target_dir)

      # Copy font to formula subdirectory
      example_font_to(filename, target_dir)

      # Rebuild fontist index so fonts are findable by new OOP architecture
      Fontist::Indexes::FontistIndex.instance.rebuild
    end

    def example_font_to_system(filename)
      raise("System dir is not stubbed") unless @system_dir

      example_font_to(filename, @system_dir)

      # CRITICAL: Delete the system index file to prevent stale cache issues
      # On Windows, the SystemIndex might use a cached index file from a previous
      # test run due to file locking preventing proper cleanup.
      system_index_path = Fontist.system_index_path
      File.delete(system_index_path) if File.exist?(system_index_path)

      # Rebuild system index so fonts are findable
      # Reset cache first to ensure we pick up the new stub
      Fontist::Indexes::SystemIndex.reset_cache
      Fontist::Indexes::SystemIndex.instance.rebuild
    end

    def example_font_to_fontist(filename)
      raise("Fontist dir is not stubbed") unless @fontist_dir

      # For fontist_dir (used in tests), also use formula-keyed structure
      formula_key = infer_formula_key_from_filename(filename)
      target_dir = File.join(@fontist_dir, formula_key)
      FileUtils.mkdir_p(target_dir)

      example_font_to(filename, target_dir)
      # Rebuild fontist index so fonts are findable
      Fontist::Indexes::FontistIndex.instance.rebuild
    end

    def example_font_to(filename, dir)
      example_path = examples_font_path(filename)
      target_path = File.join(dir, filename)
      FileUtils.cp(example_path, target_path)
    end

    def examples_font_path(filename)
      File.join("spec", "examples", "fonts", filename)
    end

    def examples_formula_path(filename)
      File.join("spec", "examples", "formulas", filename)
    end

    def no_formulas(&block)
      previous = Fontist.formulas_repo_path
      @formulas_repo_path = create_formulas_repo
      allow(Fontist).to receive(:formulas_repo_path)
        .and_return(@formulas_repo_path)

      rebuilt_index(&block)

      allow(Fontist).to receive(:formulas_repo_path).and_return(previous)
      @formulas_repo_path = nil
    end

    def create_formulas_repo
      dir = Pathname.new(Dir.mktmpdir)
      FileUtils.mkdir(dir.join("Formulas"))
      dir
    end

    def rebuilt_index
      Dir.mktmpdir do |dir|
        original = Fontist.formula_index_dir
        allow(Fontist).to receive(:formula_index_dir)
          .and_return(Pathname.new(dir))
        Fontist::Index.rebuild

        yield

        Fontist::Index.reset_cache
        allow(Fontist).to receive(:formula_index_dir).and_return(original)
      end
    end

    def formula_repo_with(example_formula, branch = "main")
      Dir.mktmpdir do |dir|
        example_formula_to(example_formula, dir)

        init_repo(dir, branch) do |git|
          git.add(example_formula)
        end

        yield dir
      end
    end

    def add_to_formula_repo(dir, example_formula)
      example_formula_to(example_formula, dir)
      add_to_repo(dir, example_formula)
    end

    def create_new_file_in_repo(repo_dir, file_to_touch)
      FileUtils.touch(File.join(repo_dir, file_to_touch))
      add_to_repo(repo_dir, file_to_touch)
    end

    def add_to_repo(repo_dir, file_to_add)
      git = Git.open(repo_dir)
      git.add(file_to_add)
      git.commit("msg")
    end

    def example_formula(path, target_path = nil)
      example_path = File.join("spec", "examples", "formulas", path)
      absolute_target_path = Fontist.formulas_path.join(target_path || path)
      FileUtils.mkdir_p(File.dirname(absolute_target_path))
      FileUtils.cp(example_path, absolute_target_path)

      Fontist::Index.rebuild
    end

    def example_formula_to(filename, dir)
      example_path = File.join("spec", "examples", "formulas", filename)
      target_path = File.join(dir, filename)
      FileUtils.cp(example_path, target_path)
    end

    def example_manifest(name)
      File.join("spec", "examples", "manifests", name)
    end

    def stub_env(name, value)
      prev = ENV.fetch(name, nil)
      ENV[name] = value
      yield
      ENV[name] = prev
    end

    def stub_system_index_path
      previous_path = Fontist.system_index_path

      path = File.join(create_tmp_dir, "system_index.yml")
      allow(Fontist).to receive(:system_index_path).and_return(path)

      yield path

      allow(Fontist).to receive(:system_index_path).and_return(previous_path)

      path
    end

    def avoid_cache(*urls)
      Utils::Cache.new.tap do |cache|
        paths = urls.map do |url|
          [url, cache.delete(url)]
        end

        yield

        paths.each do |url, path|
          cache.set(url, path) if path
        end
      end
    end

    def with_option(option)
      original = Fontist.send("#{option}?")
      Fontist.send("#{option}=", true)

      yield

      Fontist.send("#{option}=", original)
    end

    def patch_yml(path, data, *dig_path)
      key = dig_path.pop
      formula = YAML.load_file(path)
      formula.dig(*dig_path)[key] = data
      File.write(path, YAML.dump(formula))
    end

    def restore_default_settings
      Fontist.interactive = false
    end

    # Windows-safe wrapper for Dir.mktmpdir that handles file locking
    # during cleanup. Use this when installing fonts in temp directories.
    #
    # @yield [String] temp directory path
    # @return [Object] result of the block
    def safe_mktmpdir
      retry_count = 0
      begin
        Dir.mktmpdir do |dir|
          result = yield dir

          # On Windows, wait for file handles to be released
          if Fontist::Utils::System.user_os == :windows
            # Force garbage collection to release file handles
            GC.start
            sleep(0.1)
          end

          result
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

    private

    # Delete a file with retries to handle Windows file locking issues
    #
    # On Windows, files may be locked by other processes (e.g., antivirus,
    # indexing services). This method retries deletion with a small delay
    # between attempts.
    #
    # @param path [String, nil] The file path to delete. If nil, does nothing.
    # @param max_retries [Integer] Maximum number of retry attempts (default: 3)
    # @param retry_delay [Float] Delay in seconds between retries (default: 0.2)
    # @return [Boolean] true if file was deleted or didn't exist, false otherwise
    def delete_with_retry(path, max_retries: 3, retry_delay: 0.2)
      return true if path.nil? || path.empty?
      return true unless File.exist?(path)

      retry_count = 0
      begin
        File.delete(path)
        true
      rescue Errno::EACCES, Errno::ENOENT => e
        # EACCES: Permission denied (Windows file locking)
        # ENOENT: File was deleted by another process
        retry_count += 1
        if retry_count < max_retries
          sleep(retry_delay)
          retry
        end

        # Log warning but don't fail - this is cleanup code
        warn "Warning: Could not delete file after #{max_retries} attempts: #{path} (#{e.class}: #{e.message})"
        false
      end
    end

    # Infers formula key from font filename
    #
    # Examples:
    #   "overpass-regular.otf" → "overpass"
    #   "texgyrechorus-mediumitalic.otf" → "tex_gyre_chorus"
    #   "AndaleMo.TTF" → "andale"
    #   "Roboto-Regular.ttf" → "roboto"
    #
    # @param filename [String] Font filename
    # @return [String] Formula key
    def infer_formula_key_from_filename(filename)
      base = File.basename(filename, ".*").downcase

      # Common patterns to extract formula key
      # Remove common suffixes: -regular, -bold, -italic, etc.
      key = base.gsub(
        /-?(regular|bold|italic|light|medium|thin|black|oblique|mono)/, ""
      )

      # Handle special cases
      key = "andale" if /^andalemo/.match?(key)
      key = "tex_gyre_chorus" if /^texgyrechorus/.match?(key)
      key = "work_sans" if /^worksans/.match?(key)
      key = "cambria" if /^cambria/.match?(key)
      key = "fira_code" if /^firacode/.match?(key)
      key = "lato" if /^lato/.match?(key)
      key = "source" if /^source/.match?(key)

      # Remove trailing hyphens and underscores
      key.gsub(/[-_]+$/, "")
    end
  end
end
