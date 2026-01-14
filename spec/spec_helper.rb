# SimpleCov must be loaded before any application code
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
  add_group "Indexes", "lib/fontist/indexes"
  add_group "Import", "lib/fontist/import"
  add_group "Install Locations", "lib/fontist/install_locations"
  add_group "Core", "lib/fontist"

  track_files "lib/**/*.rb"
end

require "bundler/setup"
require "fontist"
require "vcr"
require "webmock/rspec"

# Configure VCR for HTTP request caching
VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body],
  }
  # Filter sensitive API keys from cassettes
  config.filter_sensitive_data("<GOOGLE_FONTS_API_KEY>") do |interaction|
    uri = URI.parse(interaction.request.uri)
    host = uri.host
    if host == "googleapis.com" || host&.end_with?(".googleapis.com")
      URI.decode_www_form(uri.query || "").to_h["key"]
    end
  end
end

# Load test isolation manager first - it defines Fontist::Test module
# that other support files depend on
require_relative "support/spec_isolation_manager"

# Load cross-platform test helpers
require_relative "support/path_helper"
require_relative "support/windows_test_helper"

# Load remaining support files (excluding spec_isolation_manager.rb)
Dir["./spec/support/**/*.rb"].sort.each do |file|
  require file unless file.end_with?("spec_isolation_manager.rb")
end

RSpec.configure do |config|
  # Include PathHelper in all specs for cross-platform path assertions
  config.include PathHelper

  # Setup Windows-specific configuration before test suite
  config.before(:suite) do
    WindowsTestHelper.setup if WindowsTestHelper.windows?
  end

  # Disable interactive prompts during tests
  config.before(:suite) do
    Fontist.interactive = false
    Fontist.ui.level = :info  # Enable UI method execution in tests
    Fontist.auto_overwrite = true  # Auto-overwrite repos to prevent yes? prompts blocking CI
  end

  # Reset all Fontist state before each test to ensure clean state for stubs
  config.before(:each) do
    # CRITICAL: Reset System cache FIRST, before any stubs, to prevent
    # caching of the real OS value from interfering with platform-specific stubs
    Fontist::Utils::System.reset_cache

    # Reset all other caches via isolation manager if available
    begin
      Fontist::Test::IsolationManager.instance.reset_all
    rescue StandardError
      # Fallback to individual resets if isolation manager not available
      Fontist::Config.reset rescue nil
      Fontist::Index.reset_cache rescue nil
      Fontist::SystemIndex.reset_cache rescue nil
      Fontist::SystemFont.reset_font_paths_cache rescue nil

      # Reset new OOP index singletons
      Fontist::Indexes::FontistIndex.reset_cache rescue nil
      Fontist::Indexes::UserIndex.reset_cache rescue nil
      Fontist::Indexes::SystemIndex.reset_cache rescue nil
    end

    # Set up a pass-through stub for user_os that calls the original method
    # This ensures the method is stubbed from the start, preventing caching
    # of the real value before test-specific stubs can be applied
    # The stub calls through to the original implementation, which respects
    # ENV['FONTIST_PLATFORM'] and other platform detection logic
    # Individual tests can override this with their own stubs
    allow(Fontist::Utils::System).to receive(:user_os).and_call_original
  end

  # Reset all Fontist state after each test for proper isolation
  config.after(:each) do
    # MINIMAL cleanup after each test - let before(:each) handle most resets
    # This prevents aggressive cleanup that might interfere with test execution
    # especially on Windows where file handles and tempfiles need care

    # CRITICAL: Explicitly reset default_fontist_path stub
    # RSpec's automatic cleanup doesn't work with disable_monkey_patching
    allow(Fontist).to receive(:default_fontist_path).and_call_original

    # DEBUG: Verify stub was reset
    $stderr.puts "DEBUG spec_helper after(:each): default_fontist_path=#{Fontist.default_fontist_path}" if ENV["DEBUG_FRESH_HOME"]

    # Always reset interactive mode
    Fontist.interactive = false

    # Reset Config to prevent state pollution from tests that modify it
    Fontist::Config.reset

    # Reset find_styles cache to prevent test pollution from performance optimizations
    Fontist::SystemFont.disable_find_styles_cache
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.include Fontist::Helper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Skip the slow tests locally
  if ENV["CI"]
    config.filter_run_excluding dev: true
  else
    config.filter_run_excluding slow: true
  end

  if Fontist::Utils::System.user_os == :windows
    config.filter_run_excluding fontconfig: true
  end

  unless ENV["CI"].nil? || Fontist::Utils::System.fontconfig_installed?
    config.filter_run_excluding fontconfig: true
  end

  %i[windows macos linux].each do |system|
    unless Fontist::Utils::System.user_os == system
      config.filter_run_excluding system => true
    end
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
