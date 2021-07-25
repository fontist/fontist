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
  spec.add_runtime_dependency "thor", "~> 1.0.1"
  spec.add_runtime_dependency "git", "~> 1.0"
  spec.add_runtime_dependency "ttfunk", "~> 1.6"
  spec.add_runtime_dependency "excavate", "~> 0.1"

  spec.add_development_dependency "extract_ttc", "~> 0.1"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "nokogiri", "~> 1.0"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "1.5.2"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "ruby-protocol-buffers", "~> 1.0"

  spec.add_runtime_dependency "socksify"
end
