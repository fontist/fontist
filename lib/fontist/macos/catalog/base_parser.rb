require "plist"
require_relative "asset"

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
          posted_date_str = posted_date
          framework_ver = framework_version
          parse_assets.map do |asset_data|
            Asset.new(asset_data, posted_date: posted_date_str,
                                  framework_version: framework_ver)
          end
        end

        def posted_date
          date_obj = data["postedDate"]
          return nil unless date_obj

          # Plist parser may return DateTime object directly
          if date_obj.is_a?(String)
            Time.parse(date_obj).utc.iso8601
          elsif date_obj.respond_to?(:to_time)
            date_obj.to_time.utc.iso8601
          else
            date_obj.to_s
          end
        rescue StandardError => e
          Fontist.ui.error("Could not parse postedDate: #{e.message}")
          nil
        end

        def catalog_version
          # Extract from filename: com_apple_MobileAsset_Font7.xml -> 7
          File.basename(@xml_path).match(/Font(\d+)/)[1].to_i
        end

        def framework_version
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
