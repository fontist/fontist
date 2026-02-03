RSpec.shared_context "empty home" do
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

    # CRITICAL: Save the formula index paths NOW while the stub is active.
    # We need to delete these specific files in the after hook.
    @formula_index_path = Fontist.formula_index_path.to_s
    @formula_preferred_family_index_path = Fontist.formula_preferred_family_index_path.to_s
    @formula_filename_index_path = Fontist.formula_filename_index_path.to_s

    Fontist::Index.reset_cache
  end

  after do
    Fontist::Index.reset_cache

    # CRITICAL: Delete formula index files using the paths saved in before hook.
    # We must use the saved paths because the stub is still active here.
    # NOTE: The default_fontist_path stub is reset by spec_helper's after(:each) hook
    File.delete(@formula_index_path) if @formula_index_path && File.exist?(@formula_index_path)
    File.delete(@formula_preferred_family_index_path) if @formula_preferred_family_index_path && File.exist?(@formula_preferred_family_index_path)
    File.delete(@formula_filename_index_path) if @formula_filename_index_path && File.exist?(@formula_filename_index_path)
  end
end
