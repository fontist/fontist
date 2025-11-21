require "fontisan"
require "tempfile"

module Fontist
  class FontFile
    class << self
      def from_path(path)
        font_info = extract_font_info_from_path(path)
        new(font_info)
      end

      def from_content(content)
        Tempfile.create(['font', '.ttf']) do |tmpfile|
          tmpfile.binmode
          tmpfile.write(content)
          tmpfile.flush

          font_info = extract_font_info_from_path(tmpfile.path)
          return new(font_info)
        end
      rescue StandardError => e
        raise_font_file_error(e)
      end

      private

      def extract_font_info_from_path(path)
        # Load font using Fontisan's Ruby API
        font = Fontisan::FontLoader.load(path)
        extract_names_from_font(font)
      rescue StandardError => e
        raise_font_file_error(e)
      end

      def extract_names_from_font(font)
        # Access name table directly
        name_table = font.table(Fontisan::Constants::NAME_TAG)
        return {} unless name_table

        # Extract all needed name strings using Fontisan's API
        {
          full_name: name_table.english_name(Fontisan::Tables::Name::FULL_NAME),
          family_name: name_table.english_name(Fontisan::Tables::Name::FAMILY),
          subfamily_name: name_table.english_name(Fontisan::Tables::Name::SUBFAMILY),
          preferred_family: name_table.english_name(Fontisan::Tables::Name::PREFERRED_FAMILY),
          preferred_subfamily: name_table.english_name(Fontisan::Tables::Name::PREFERRED_SUBFAMILY),
          postscript_name: name_table.english_name(Fontisan::Tables::Name::POSTSCRIPT_NAME)
        }
      end

      def raise_font_file_error(exception)
        raise Errors::FontFileError,
              "Font file could not be parsed: #{exception.inspect}."
      end
    end

    def initialize(font_info)
      @info = font_info
    end

    def full_name
      @info[:full_name]
    end

    def family
      @info[:family_name]
    end

    def subfamily
      @info[:subfamily_name]
    end

    def preferred_family
      @info[:preferred_family]
    end

    def preferred_subfamily
      @info[:preferred_subfamily]
    end
  end
end
