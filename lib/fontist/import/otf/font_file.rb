require_relative "../font_metadata_extractor"
require_relative "../files/font_detector"

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

        def initialize(path, name_prefix: nil)
          @path = path
          @name_prefix = name_prefix
          @extension = detect_extension
          @metadata = extract_metadata
        end

        def to_style
          STYLE_ATTRIBUTES.to_h { |name| [name, send(name)] }.compact
        end

        def to_collection_style
          COLLECTION_ATTRIBUTES.to_h { |name| [name, send(name)] }.compact
        end

        def family_name
          name = @metadata.family_name
          @name_prefix ? "#{@name_prefix}#{name}" : name
        end

        def type
          @metadata.subfamily_name
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

        def font
          basename = File.basename(@path, ".*").chomp(".#{@extension}")

          "#{basename}.#{@extension}"
        end

        def source_font
          File.basename(@path) unless font == File.basename(@path)
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
        end

        def detect_extension
          detected = Files::FontDetector.standard_extension(@path)
          file_extension = File.extname(File.basename(@path)).sub(/^\./, "")
          return file_extension if file_extension.casecmp?(detected)

          detected
        end
      end
    end
  end
end
