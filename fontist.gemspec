lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fontist/version"

Gem::Specification.new do |spec|
  spec.name          = "fontist"
  spec.version       = Fontist::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Install openly-licensed fonts on Windows, Linux and Mac!"
  spec.description   = "Install openly-licensed fonts on Windows, Linux and Mac!"
  spec.homepage      = "https://github.com/fontist/fontist"
  spec.license       = "BSD-2-Clause"

  spec.post_install_message = "Please run `fontist update` to fetch formulas."

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fontist/fontist"
  spec.metadata["changelog_uri"] = "https://github.com/fontist/fontist"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(bin|test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = ["fontist"]

  spec.add_dependency "down", "~> 5.0"
  spec.add_dependency "excavate", "~> 0.3", ">= 0.3.8"
  spec.add_dependency "extract_ttc", "~> 0.3.7"
  spec.add_dependency "fuzzy_match", "~> 2.1"
  spec.add_dependency "git", "~> 4.0"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "lutaml-model", "~> 0.7"
  spec.add_dependency "mime-types", "~> 3.0"
  spec.add_dependency "nokogiri", "~> 1.0"
  spec.add_dependency "plist", "~> 3.0"
  spec.add_dependency "socksify", "~> 1.7"
  spec.add_dependency "sys-uname", "~> 1.2"
  spec.add_dependency "thor", "~> 1.4"
  spec.add_dependency "ttfunk", "~> 1.6"
end
