require "fontisan"

module Fontist
  module Import
    module Files
      class FontDetector
        # Font format to extension mapping
        FONT_EXTENSIONS = {
          "truetype" => "ttf",
          "cff" => "otf",
        }.freeze

        class << self
          def detect(path)
            info = brief_info(path)
            return :other unless info

            # Check if it's a collection based on the info type
            if collection_info?(info)
              :collection
            elsif font_info?(info)
              :font
            else
              :other
            end
          end

          def standard_extension(path)
            info = brief_info(path)
            return nil unless info

            # For collections, always use ttc
            if collection_info?(info)
              return "ttc"
            end

            # For single fonts, map format to extension
            font_format = get_font_format(info)
            extension = FONT_EXTENSIONS[font_format]
            return extension if extension

            # Fallback to file extension if format unknown
            File.extname(path).sub(/^\./, "").downcase
          rescue StandardError
            raise Errors::UnknownFontTypeError.new(path)
          end

          private

          def brief_info(path)
            # Use Fontisan brief mode for fast font detection
            Fontisan.info(path, brief: true)
          rescue StandardError => e
            # Not a valid font file
            Fontist.ui.debug("Fontisan brief info failed for #{path}: #{e.message}")
            nil
          end

          def collection_info?(info)
            info.is_a?(Fontisan::Models::CollectionBriefInfo)
          end

          def font_info?(info)
            info.is_a?(Fontisan::Models::FontInfo)
          end

          def get_font_format(info)
            if collection_info?(info)
              # For collections, get format from first font
              info.fonts.first&.font_format
            else
              # For single fonts
              info.font_format
            end
          end
        end
      end
    end
  end
end
