module Fontist
  module Macos
    module Catalog
      # Represents a font asset from macOS Font7/Font8 catalog
      # Each asset contains one or more fonts with their metadata
      class Asset
        attr_reader :base_url, :relative_path, :font_info, :build,
                    :compatibility_version, :design_languages, :prerequisite

        def initialize(data)
          @base_url = data["__BaseURL"]
          @relative_path = data["__RelativePath"]
          @font_info = data["FontInfo4"] || []
          @build = data["Build"]
          @compatibility_version = data["_CompatibilityVersion"]
          @design_languages = data["FontDesignLanguages"] || []
          @prerequisite = data["Prerequisite"] || []
        end

        def download_url
          "#{@base_url}#{@relative_path}"
        end

        def fonts
          @font_info.map { |info| FontInfo.new(info) }
        end

        def postscript_names
          fonts.map(&:postscript_name).compact
        end

        def font_families
          fonts.map(&:font_family_name).compact.uniq
        end

        def primary_family_name
          font_families.first
        end
      end

      # Represents metadata for a single font within an asset
      class FontInfo
        attr_reader :postscript_name, :font_family_name, :font_style_name,
                    :preferred_family_name, :preferred_style_name,
                    :platform_delivery

        def initialize(data)
          @data = data
          @postscript_name = data["PostScriptFontName"]
          @font_family_name = data["FontFamilyName"]
          @font_style_name = data["FontStyleName"]
          @preferred_family_name = data["PreferredFamilyName"]
          @preferred_style_name = data["PreferredStyleName"]
          @platform_delivery = data["PlatformDelivery"] || []
        end

        def display_names
          @data["DisplayNames"] || {}
        end

        def macos_compatible?
          # No platform delivery means compatible with all
          return true if @platform_delivery.empty?

          # Check if any platform delivery includes macOS (but not invisible)
          @platform_delivery.any? do |platform|
            platform.include?("macOS") && platform != "macOS-invisible"
          end
        end
      end
    end
  end
end
