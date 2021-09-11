require "rspec-benchmark"

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end

RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = true
end
