require_relative "font3_parser"
require_relative "font4_parser"
require_relative "font5_parser"
require_relative "font6_parser"
require_relative "font7_parser"
require_relative "font8_parser"

module Fontist
  module Macos
    module Catalog
      # Manages macOS Font catalogs across different versions
      # Provides discovery, version detection, and parser selection
      class CatalogManager
        CATALOG_BASE_PATH = "/System/Library/AssetsV2".freeze

        class << self
          def available_catalogs
            Dir.glob("#{CATALOG_BASE_PATH}/com_apple_MobileAsset_Font*/*.xml")
              .sort
          end

          def parser_for(catalog_path)
            version = detect_version(catalog_path)

            case version
            when 3
              Font3Parser.new(catalog_path)
            when 4
              Font4Parser.new(catalog_path)
            when 5
              Font5Parser.new(catalog_path)
            when 6
              Font6Parser.new(catalog_path)
            when 7
              Font7Parser.new(catalog_path)
            when 8
              Font8Parser.new(catalog_path)
            else
              raise ArgumentError,
                    "Unsupported Font catalog version: #{version}. " \
                    "Supported versions: 3, 4, 5, 6, 7, 8"
            end
          end

          def detect_version(catalog_path)
            # Extract version from directory name or filename
            # e.g., /path/com_apple_MobileAsset_Font7/file.xml -> 7
            match = catalog_path.match(/Font(\d+)/)

            unless match
              raise ArgumentError,
                    "Cannot detect version from: #{catalog_path}"
            end

            match[1].to_i
          end

          def all_assets
            available_catalogs.flat_map do |catalog_path|
              parser_for(catalog_path).assets
            end
          end

          def latest_catalog
            available_catalogs.last
          end

          def catalog_for_version(version)
            available_catalogs.find do |path|
              path.include?("Font#{version}")
            end
          end
        end
      end
    end
  end
end
