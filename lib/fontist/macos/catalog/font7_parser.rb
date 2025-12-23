require_relative "base_parser"

module Fontist
  module Macos
    module Catalog
      # Parser for Font7 catalogs (macOS Monterey, Ventura, Sonoma)
      # All fonts in Font7 are macOS-compatible, no filtering needed
      class Font7Parser < BaseParser
        # No overrides needed - all assets are macOS-compatible by default
      end
    end
  end
end
