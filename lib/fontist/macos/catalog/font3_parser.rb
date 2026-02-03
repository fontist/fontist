require_relative "base_parser"

module Fontist
  module Macos
    module Catalog
      # Parser for Font3 catalogs (macOS Yosemite, El Capitan, Sierra)
      # All fonts in Font3 are macOS-compatible, no filtering needed
      class Font3Parser < BaseParser
        # No overrides needed - all assets are macOS-compatible by default
      end
    end
  end
end
