lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fontist/version"

Gem::Specification.new do |spec|
  spec.name          = "fontist"
  spec.version       = Fontist::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = %q{Install openly-licensed fonts on Windows, Linux and Mac!}
  spec.description   = %q{Install openly-licensed fonts on Windows, Linux and Mac!}
  spec.homepage      = "https://github.com/fontist/fontist"
  spec.license       = "BSD-2-Clause"

  spec.post_install_message = "Please run `fontist update` to fetch formulas."

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fontist/fontist"
  spec.metadata["changelog_uri"] = "https://github.com/fontist/fontist"

  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(bin|test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = ["fontist"]
  spec.test_files    = `git ls-files -- {spec}/*`.split("\n")

  spec.add_runtime_dependency "down", "~> 5.0"
  spec.add_runtime_dependency "extract_ttc", "~> 0.1"
  spec.add_runtime_dependency "fuzzy_match", "~> 2.1"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_runtime_dependency "nokogiri", "~> 1.0"
  spec.add_runtime_dependency "mime-types", "~> 3.0"
  spec.add_runtime_dependency "sys-uname", "~> 1.2"
  spec.add_runtime_dependency "thor", "~> 1.2", ">= 1.2.1"
  spec.add_runtime_dependency "git", "~> 1.0"
  spec.add_runtime_dependency "ttfunk", "~> 1.6"
  spec.add_runtime_dependency "plist", "~> 3.0"
  spec.add_runtime_dependency "excavate", "~> 0.3", '>= 0.3.4'
  spec.add_runtime_dependency "socksify", "~> 1.7"

  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-benchmark", "~> 0.6"
  spec.add_development_dependency "rubocop", "~> 1.22.1"
  spec.add_development_dependency "rubocop-rails", "~> 2.9"
  spec.add_development_dependency "rubocop-performance", "~> 1.10"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
end
