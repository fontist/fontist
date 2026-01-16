require_relative "../font_metadata_extractor"

module Fontist
  module Import
    module Otf
      class FontFile
        STYLE_ATTRIBUTES = %i[family_name type preferred_family_name
                              preferred_type full_name post_script_name
                              version description copyright font
                              source_font].freeze

        COLLECTION_ATTRIBUTES = STYLE_ATTRIBUTES.reject do |a|
          %i[font source_font].include?(a)
        end

        attr_reader :path

        def initialize(path_or_metadata, name_prefix: nil, metadata: nil)
          if metadata
            # Use pre-built metadata (for collection fonts without tempfiles)
            @path = path_or_metadata.to_s
            @metadata = metadata
          else
            # Extract metadata from file path (backward compatibility)
            @path = path_or_metadata
            @metadata = extract_metadata
          end
          @name_prefix = name_prefix
        end

        def to_style
          STYLE_ATTRIBUTES.to_h { |name| [name, send(name)] }.compact
        end

        def to_collection_style
          COLLECTION_ATTRIBUTES.to_h { |name| [name, send(name)] }.compact
        end

        def family_name
          name = @metadata.family_name || "Unknown"
          @name_prefix ? "#{@name_prefix}#{name}" : name
        end

        def type
          @metadata.subfamily_name || "Regular"
        end

        def preferred_family_name
          name = @metadata.preferred_family_name
          return unless name

          @name_prefix ? "#{@name_prefix}#{name}" : name
        end

        def preferred_type
          @metadata.preferred_subfamily_name
        end

        def full_name
          @metadata.full_name
        end

        def post_script_name
          @metadata.postscript_name
        end

        def version
          @metadata.version
        end

        def description
          @metadata.description
        end

        # rubocop:disable Layout/LineLength
        # Use the exact filename from the archive - do NOT modify or standardize it
        # rubocop:enable Layout/LineLength
        def font
          File.basename(@path)
        end

        def source_font
          # source_font is only used when font != original filename
          # Since we now use exact filename, this should always be nil
          nil
        end

        def copyright
          @metadata.copyright
        end

        def homepage
          @metadata.vendor_url
        end

        def license_url
          @metadata.license_url
        end

        private

        def extract_metadata
          FontMetadataExtractor.new(@path).extract
        rescue StandardError => e
          # rubocop:disable Layout/LineLength
          # Return a minimal metadata object if extraction fails
          Fontist.ui.error("WARN: Could not extract metadata from #{@path}: #{e.message}")
          # rubocop:enable Layout/LineLength
          Models::FontMetadata.new(
            family_name: File.basename(@path, ".*"),
            subfamily_name: "Regular",
          )
        end
      end
    end
  end
end
