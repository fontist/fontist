require "plist"

module Fontist
  module Macos
    module Catalog
      # Base parser for macOS Font catalogs
      # Handles common parsing logic for Font7, Font8, etc.
      class BaseParser
        attr_reader :xml_path

        def initialize(xml_path)
          @xml_path = xml_path
          @data = nil
        end

        def assets
          parse_assets.map { |asset_data| Asset.new(asset_data) }
        end

        def catalog_version
          # Extract from filename: com_apple_MobileAsset_Font7.xml -> 7
          File.basename(@xml_path).match(/Font(\d+)/)[1].to_i
        end

        private

        def parse_assets
          data["Assets"] || []
        end

        def data
          @data ||= Plist.parse_xml(File.read(@xml_path))
        end
      end
    end
  end
end
