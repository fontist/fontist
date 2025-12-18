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

# Load remaining support files (excluding spec_isolation_manager.rb)
Dir["./spec/support/**/*.rb"].sort.each do |file|
  require file unless file.end_with?("spec_isolation_manager.rb")
end

RSpec.configure do |config|
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
