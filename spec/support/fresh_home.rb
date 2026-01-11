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

    stub_system_fonts

    FileUtils.mkdir_p(Fontist.fonts_path)
    FileUtils.mkdir_p(Fontist.formulas_path)

    Fontist::Config.reset
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::Indexes::FontistIndex.reset_cache
    Fontist::Indexes::UserIndex.reset_cache
  end

  after do
    # Restore original formulas_path
    Fontist.formulas_path = @orig_formulas_path

    # CRITICAL: Remove the stub completely to avoid side effects
    # This allows default_fontist_path to work normally in subsequent tests
    allow(Fontist).to receive(:default_fontist_path).and_call_original

    # Restore original ENV values
    ENV["FONTIST_USER_FONTS_PATH"] = @orig_user_path
    ENV["FONTIST_SYSTEM_FONTS_PATH"] = @orig_system_path

    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::Indexes::FontistIndex.reset_cache
    Fontist::Indexes::UserIndex.reset_cache
    Fontist::Indexes::SystemIndex.reset_cache
  end
end
