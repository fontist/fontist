require_relative "file_requirement"

module Fontist
  module Import
    module Files
      class FontDetector
        REQUIREMENTS = { file: FileRequirement.new }.freeze

        FONT_LABELS = ["OpenType font data",
                       "TrueType Font data"].freeze

        COLLECTION_LABEL = "TrueType font collection data".freeze

        FONT_EXTENSIONS = {
          "OpenType font data" => "otf",
          "TrueType Font data" => "ttf",
          "TrueType font collection data" => "ttc",
        }.freeze

        def self.detect(path)
          brief = file_brief(path)

          if brief.start_with?(*FONT_LABELS)
            :font
          elsif brief.start_with?(COLLECTION_LABEL)
            :collection
          else
            :other
          end
        end

        def self.standard_extension(path)
          brief = file_brief(path)

          FONT_EXTENSIONS.each do |label, extension|
            return extension if brief.start_with?(label)
          end

          raise Errors::UnknownFontTypeError.new(path)
        end

        def self.file_brief(path)
          REQUIREMENTS[:file].call(path)
        end
      end
    end
  end
end
