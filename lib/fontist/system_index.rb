require "ttfunk"

module Fontist
  class SystemIndex
    include Utils::Locking

    class DefaultFamily
      def family_name(name)
        name.font_family
      end

      def type(name)
        name.font_subfamily
      end
    end

    class PreferredFamily
      def family_name(name)
        return name.font_family if name.preferred_family.empty?

        name.preferred_family
      end

      def type(name)
        return name.font_subfamily if name.preferred_subfamily.empty?

        name.preferred_subfamily
      end
    end

    PLATFORM_MACINTOSH = 1
    PLATFORM_MICROSOFT = 3

    ENCODING_MAC_ROMAN = 0
    ENCODING_MS_UNICODE_BMP = 1

    LANGUAGE_MAC_ENGLISH = 0
    LANGUAGE_MS_ENGLISH_AMERICAN = 0x409

    attr_reader :font_paths

    def self.system_index
      if Fontist.preferred_family?
        new(Fontist.system_preferred_family_index_path,
            SystemFont.font_paths,
            PreferredFamily.new)
      else
        new(Fontist.system_index_path,
            SystemFont.font_paths,
            DefaultFamily.new)
      end
    end

    def self.fontist_index
      if Fontist.preferred_family?
        new(Fontist.fontist_preferred_family_index_path,
            SystemFont.fontist_font_paths,
            PreferredFamily.new)
      else
        new(Fontist.fontist_index_path,
            SystemFont.fontist_font_paths,
            DefaultFamily.new)
      end
    end

    def initialize(index_path, font_paths, family)
      @index_path = index_path
      @font_paths = font_paths
      @family = family
    end

    def find(font, style)
      fonts = index.select do |file|
        file[:family_name].casecmp?(font) &&
          (style.nil? || file[:type].casecmp?(style))
      end

      fonts.empty? ? nil : fonts
    end

    def rebuild
      build_index
    end

    private

    def index
      @index ||= build_index
    end

    def build_index
      lock(lock_path) do
        do_build_index
      end
    end

    def lock_path
      "#{@index_path}.lock"
    end

    def do_build_index
      previous_index = load_index
      updated_index = detect_paths(font_paths, previous_index)
      updated_index.tap do |index|
        save_index(index) if changed?(updated_index, previous_index)
      end
    end

    def changed?(this, other)
      this.map { |x| x[:path] }.uniq.sort != other.map { |x| x[:path] }.uniq.sort
    end

    def load_index
      index = File.exist?(@index_path) ? YAML.load_file(@index_path) : []
      check_index(index)
      index
    end

    def check_index(index)
      index.each do |item|
        missing_keys = %i[path full_name family_name type] - item.keys
        unless missing_keys.empty?
          raise(Errors::FontIndexCorrupted, <<~MSG.chomp)
            Font index is corrupted.
            Item #{item.inspect} misses required attributes: #{missing_keys.join(', ')}.
            You can remove the index file (#{@index_path}) and try again.
          MSG
        end
      end
    end

    def detect_paths(paths, index)
      by_path = index.group_by { |x| x[:path] }

      paths.flat_map do |path|
        next by_path[path] if by_path[path]

        detect_fonts(path)
      end.compact
    end

    def detect_fonts(path)
      case File.extname(path).gsub(/^\./, "").downcase
      when "ttf", "otf"
        detect_file_font(path)
      when "ttc"
        detect_collection_fonts(path)
      else
        raise Errors::UnknownFontTypeError.new(path)
      end
    end

    def detect_file_font(path)
      content = File.read(path, mode: "rb")
      file = TTFunk::File.new(content)

      parse_font(file, path)
    rescue StandardError
      warn $!.message
      warn "Warning: File at #{path} not recognized as a font file."
    end

    def detect_collection_fonts(path)
      TTFunk::Collection.open(path) do |collection|
        collection.map do |file|
          parse_font(file, path)
        end
      end
    rescue StandardError
      warn $!.message
      warn "Warning: File at #{path} not recognized as a font file."
    end

    def parse_font(file, path)
      x = file.name

      {
        path: path,
        full_name: english_name(x.font_name),
        family_name: english_name(@family.family_name(x)),
        type: english_name(@family.type(x)),
      }
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

    def save_index(index)
      dir = File.dirname(@index_path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.write(@index_path, YAML.dump(index))
    end
  end
end
