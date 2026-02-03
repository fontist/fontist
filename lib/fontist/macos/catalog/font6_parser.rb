require_relative "base_parser"

module Fontist
  module Macos
    module Catalog
      # Parser for Font6 catalogs (macOS Big Sur)
      # All fonts in Font6 are macOS-compatible, no filtering needed
      class Font6Parser < BaseParser
        # No overrides needed - all assets are macOS-compatible by default
      end
    end
  end
end
