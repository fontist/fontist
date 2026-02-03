RSpec.shared_context "system fonts" do
  attr_reader :system_dir

  around do |example|
    retry_count = 0
    begin
      Dir.mktmpdir do |dir|
        @system_dir = dir

        example.run

        @system_dir = nil

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
    new_paths = system_paths(system_dir)
    allow(Fontist::SystemFont).to receive(:system_config).and_return(new_paths)

    disable_system_font_paths_caching
  end

  after do
    # Reset the system_config stub to prevent test pollution
    allow(Fontist::SystemFont).to receive(:system_config).and_call_original

    # Reset the system_font_paths stub set by disable_system_font_paths_caching
    allow(Fontist::SystemFont).to receive(:system_font_paths).and_call_original

    # Reset the system_file_path stub set by stub_system_fonts
    allow(Fontist).to receive(:system_file_path).and_call_original

    # Delete the system index file that was created during the test
    # This prevents the next test from finding fonts that were installed to the temp system dir
    system_index_path = Fontist.system_index_path
    File.delete(system_index_path) if File.exist?(system_index_path)

    # Reset indexes to clear any cached system font data
    Fontist::Indexes::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::SystemFont.disable_find_styles_cache
  end
end
