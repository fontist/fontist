require_relative "base_parser"

module Fontist
  module Macos
    module Catalog
      # Parser for Font4 catalogs (macOS Sierra, High Sierra)
      # All fonts in Font4 are macOS-compatible, no filtering needed
      class Font4Parser < BaseParser
        # No overrides needed - all assets are macOS-compatible by default
      end
    end
  end
end