lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fontist/version"

Gem::Specification.new do |spec|
  spec.name          = "fontist"
  spec.version       = Fontist::VERSION
  spec.authors       = ["Ribose Inc.", "Abu Nashir"]
  spec.email         = ["operations@ribose.com", "abunashir@gmail.com"]

  spec.summary       = %q{A libarary find or download fonts}
  spec.description   = %q{A libarary find or download fonts}
  spec.homepage      = "https://github.com/fontist/fontist"
  spec.license       = "BSD-2-Clause"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fontist/fontist"
  spec.metadata["changelog_uri"] = "https://github.com/fontist/fontist"

  spec.require_paths = ["lib"]
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {spec}/*`.split("\n")

  spec.add_runtime_dependency "down", "~> 5.0"
  spec.add_runtime_dependency "libmspack", "~> 0.1.0"
  spec.add_runtime_dependency "rubyzip", "~> 2.3.0"
  spec.add_runtime_dependency "thor", "~> 1.0.1"
  spec.add_runtime_dependency "git", "~> 1.0"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "ruby-protocol-buffers", "~> 1.0"
end
