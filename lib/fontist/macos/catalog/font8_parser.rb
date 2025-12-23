require_relative "base_parser"

module Fontist
  module Macos
    module Catalog
      # Parser for Font8 catalogs (macOS Sequoia)
      # Filters assets by PlatformDelivery to include only macOS-compatible fonts
      class Font8Parser < BaseParser
        private

        # Override to filter macOS-compatible assets only
        def parse_assets
          super.select { |asset| macos_compatible?(asset) }
        end

        def macos_compatible?(asset)
          # Check PlatformDelivery at asset level
          platform_delivery = asset["PlatformDelivery"]

          # No platform delivery means compatible with all
          return true if platform_delivery.nil? || platform_delivery.empty?

          # Check if any platform includes macOS (but not invisible)
          platform_delivery.any? do |platform|
            platform.include?("macOS") && platform != "macOS-invisible"
          end
        end
      end
    end
  end
end
