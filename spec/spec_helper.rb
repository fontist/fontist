require "bundler/setup"
require "fontist"

Dir["./spec/support/**/*.rb"].sort.each { |file| require file }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.include Fontist::Helper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Skip the actual file_download by default
  config.filter_run_excluding file_download: true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
