require "fontisan"
require_relative "models/font_metadata"

module Fontist
  module Import
    class FontMetadataExtractor
      def initialize(path)
        @path = path
      end

      def extract
        # Use FontLoader directly for consistent handling of both
        # individual fonts and collections (TTC/OTC)
        # For TTC files, loads the first font (index 0) by default
        font = Fontisan::FontLoader.load(
          @path,
          font_index: 0,
          mode: Fontisan::LoadingModes::METADATA
        )

        build_metadata_from_font(font)
      rescue StandardError => e
        raise Errors::FontExtractError,
              "Failed to extract metadata from #{@path}: #{e.message}"
      end

      private

      def build_metadata_from_font(font)
        name_table = font.table(Fontisan::Constants::NAME_TAG)
        os2_table = font.table(Fontisan::Constants::OS2_TAG)
        head_table = font.table(Fontisan::Constants::HEAD_TAG)

        Models::FontMetadata.new(
          family_name: name_table&.english_name(Fontisan::Tables::Name::FAMILY),
          subfamily_name: name_table&.english_name(Fontisan::Tables::Name::SUBFAMILY),
          full_name: name_table&.english_name(Fontisan::Tables::Name::FULL_NAME),
          postscript_name: name_table&.english_name(Fontisan::Tables::Name::POSTSCRIPT_NAME),
          preferred_family_name: name_table&.english_name(Fontisan::Tables::Name::PREFERRED_FAMILY),
          preferred_subfamily_name: name_table&.english_name(Fontisan::Tables::Name::PREFERRED_SUBFAMILY),
          version: clean_version(name_table&.english_name(Fontisan::Tables::Name::VERSION)),
          copyright: name_table&.english_name(Fontisan::Tables::Name::COPYRIGHT),
          description: name_table&.english_name(Fontisan::Tables::Name::LICENSE_DESCRIPTION),
          vendor_url: name_table&.english_name(Fontisan::Tables::Name::VENDOR_URL),
          license_url: name_table&.english_name(Fontisan::Tables::Name::LICENSE_URL),
          font_format: detect_font_format(font),
          is_variable: font.has_table?(Fontisan::Constants::FVAR_TAG),
        )
      end

      def detect_font_format(font)
        case font
        when Fontisan::TrueTypeFont
          "truetype"
        when Fontisan::OpenTypeFont
          "cff"
        else
          "unknown"
        end
      end

      def clean_version(version)
        return nil unless version

        version.to_s.gsub(/^Version\s+/i, "")
      end
    end
  end
end
