require "bundler/setup"
require "fontist"

Dir["./spec/support/**/*.rb"].sort.each { |file| require file }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.include Fontist::Helper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Skip the slow tests locally
  unless ENV.fetch("TEST_ENV", "local").upcase === "CI"
    config.filter_run_excluding slow: true
  end

  if Fontist::Utils::System.user_os == :windows
    config.filter_run_excluding fontconfig: true
  end

  unless ENV.fetch("TEST_ENV", "local").upcase === "CI" ||
      Fontist::Utils::System.fontconfig_installed?
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
