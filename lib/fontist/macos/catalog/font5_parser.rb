require_relative "base_parser"

module Fontist
  module Macos
    module Catalog
      # Parser for Font5 catalogs (macOS High Sierra, Mojave, Catalina)
      # All fonts in Font5 are macOS-compatible, no filtering needed
      class Font5Parser < BaseParser
        # No overrides needed - all assets are macOS-compatible by default
      end
    end
  end
end