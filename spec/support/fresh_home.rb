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
    allow(Fontist).to receive(:default_fontist_path)
      .and_return(Pathname.new(temp_dir))

    stub_system_fonts

    FileUtils.mkdir_p(Fontist.fonts_path)
    FileUtils.mkdir_p(Fontist.formulas_path)

    Fontist::Config.reset
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
  end

  after do
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
  end
end
