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

# yeptris is a runtime dependency (see the gemspec): the JSON backend in
# lib/fontist/json.rb loads it unconditionally. The optional YAML engine
# activated with FONTIST_YAML=yeptris stays off by default pending
# leptris/yeptris#863 (linux scalar-parity fix).

# Profiling tools (development only)
# gem "ruby-prof", "~> 1.7"
# stackprof uses Unix-specific system calls and doesn't compile on Windows
# gem "stackprof", "~> 0.2", install_if: -> { RUBY_PLATFORM !~ /mingw|mswin/ }
