require "bundler/setup"
require "fontist"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Skip the actual API calls by default
  config.filter_run_excluding api_call: true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
