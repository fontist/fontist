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
end
