source "https://rubygems.org"

# Specify your gem's dependencies in fontist.gemspec
gemspec

gem "bundler"
gem "openssl", "~> 3.0"
gem "ostruct"
gem "pry"
gem "rake"
gem "rspec"
gem "rspec-benchmark"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rails"
gem "rubocop-rake"
gem "simplecov"
gem "vcr"
gem "webmock"

# Optional YAML engine (consumer-side dependency; needs Ruby >= 3.0,
# which is above fontist's gemspec floor, so it stays out of the
# gemspec). Activated with FONTIST_YAML=yeptris; off by default
# pending leptris/yeptris#863 (linux scalar-parity fix).
gem "yeptris", require: false

# Profiling tools (development only)
# gem "ruby-prof", "~> 1.7"
# stackprof uses Unix-specific system calls and doesn't compile on Windows
# gem "stackprof", "~> 0.2", install_if: -> { RUBY_PLATFORM !~ /mingw|mswin/ }
