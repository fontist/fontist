# RSpec configuration for test isolation
#
# This configuration ensures proper test isolation by resetting
# all stateful components before each test runs.

RSpec.configure do |config|
  # Reset all cached state before each test
  # This ensures tests don't interfere with each other
  # Skip for performance tests which need persistent cached state
  config.before(:each) do |example|
    # Skip isolation for performance tests - they need cached state
    next if example.metadata[:type] == :performance
    next if example.file_path.include?("performance_spec.rb")

    Fontist::Test::IsolationManager.instance.reset_all
  end

  # Clean up after suite completes
  config.after(:suite) do
    Fontist::Test::IsolationManager.reset!
  end
end
