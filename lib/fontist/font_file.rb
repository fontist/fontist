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
        tmpfile = Tempfile.new(["font", ".ttf"])
        tmpfile.binmode
        tmpfile.write(content)
        tmpfile.flush
        tmpfile.close

        font_info = extract_font_info_from_path(tmpfile.path)
        # Keep tempfile alive to prevent GC issues on Windows
        # Return both the font object and tempfile so caller can keep it referenced
        new(font_info, tmpfile)
      rescue StandardError => e
        raise_font_file_error(e)
      end

      private

      def extract_font_info_from_path(path)
        # Load font using Fontisan's metadata-only mode with lazy loading for
        # maximum performance during system font indexing. This combination:
        # - Metadata mode: Loads only 6 essential tables vs ~15-20 tables
        # - Lazy loading: Defers table parsing until tables are accessed
        # Together this provides ~5x speedup according to fontisan benchmarks
        font = Fontisan::FontLoader.load(path, mode: :metadata, lazy: true)
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
          postscript_name: name_table.english_name(Fontisan::Tables::Name::POSTSCRIPT_NAME),
        }
      end

      def raise_font_file_error(exception)
        raise Errors::FontFileError,
              "Font file could not be parsed: #{exception.inspect}."
      end
    end

    def initialize(font_info, tempfile = nil)
      @info = font_info
      # Keep tempfile alive to prevent GC issues on Windows
      @tempfile = tempfile
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

    def preferred_family_name
      @info[:preferred_family]
    end

    def preferred_subfamily_name
      @info[:preferred_subfamily]
    end
  end
end
