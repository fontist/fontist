require "ttfunk"

module Fontist
  class FontFile
    PLATFORM_MACINTOSH = 1
    PLATFORM_MICROSOFT = 3

    ENCODING_MAC_ROMAN = 0
    ENCODING_MS_UNICODE_BMP = 1

    LANGUAGE_MAC_ENGLISH = 0
    LANGUAGE_MS_ENGLISH_AMERICAN = 0x409

    class << self
      def from_path(path)
        content = File.read(path, mode: "rb")

        from_content(content)
      end

      def from_content(content)
        new(build_font(content))
      end

      def from_collection_index(collection, index)
        new(build_font_from_collection_index(collection, index))
      end

      private

      def build_font(content)
        TTFunk::File.new(content)
      rescue StandardError => e
        raise_font_file_error(e)
      end

      def build_font_from_collection_index(collection, index)
        collection[index]
      rescue StandardError => e
        raise_font_file_error(e)
      end

      def raise_font_file_error(exception)
        raise Errors::FontFileError,
              "Font file could not be parsed: #{exception.inspect}."
      end
    end

    def initialize(ttfunk_file)
      @file = ttfunk_file
    end

    def full_name
      english_name(main_name.font_name)
    end

    def family
      english_name(main_name.font_family)
    end

    def subfamily
      english_name(main_name.font_subfamily)
    end

    def preferred_family
      return if main_name.preferred_family.empty?

      english_name(main_name.preferred_family)
    end

    def preferred_subfamily
      return if main_name.preferred_subfamily.empty?

      english_name(main_name.preferred_subfamily)
    end

    private

    def main_name
      @main_name ||= @file.name
    end

    def english_name(name)
      visible_characters(find_english(name))
    end

    def find_english(name)
      name.find { |x| microsoft_english?(x) } ||
        name.find { |x| mac_english?(x) } ||
        name.last
    end

    def microsoft_english?(string)
      string.platform_id == PLATFORM_MICROSOFT &&
        string.encoding_id == ENCODING_MS_UNICODE_BMP &&
        string.language_id == LANGUAGE_MS_ENGLISH_AMERICAN
    end

    def mac_english?(string)
      string.platform_id == PLATFORM_MACINTOSH &&
        string.encoding_id == ENCODING_MAC_ROMAN &&
        string.language_id == LANGUAGE_MAC_ENGLISH
    end

    def visible_characters(text)
      text.gsub(/[^[:print:]]/, "").to_s
    end
  end
end
