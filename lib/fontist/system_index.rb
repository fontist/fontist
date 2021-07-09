require "ttfunk"

module Fontist
  class SystemIndex
    PLATFORM_MACINTOSH = 1
    PLATFORM_MICROSOFT = 3

    ENCODING_MAC_ROMAN = 0
    ENCODING_MS_UNICODE_BMP = 1

    LANGUAGE_MAC_ENGLISH = 0
    LANGUAGE_MS_ENGLISH_AMERICAN = 0x409

    include Utils::Locking

    attr_reader :font_paths

    def self.find(font, style)
      new(SystemFont.font_paths).find(font, style)
    end

    def self.rebuild
      new(SystemFont.font_paths).rebuild
    end

    def initialize(font_paths)
      @font_paths = font_paths
    end

    def find(font, style)
      fonts = system_index.select do |file|
        file[:family_name].casecmp?(font) &&
          (style.nil? || file[:type].casecmp?(style))
      end

      fonts.empty? ? nil : fonts
    end

    def rebuild
      build_system_index
    end

    private

    def system_index
      @system_index ||= build_system_index
    end

    def build_system_index
      lock(lock_path) do
        do_build_system_index
      end
    end

    def lock_path
      Fontist.system_index_path.to_s + ".lock"
    end

    def do_build_system_index
      previous_index = load_system_index
      updated_index = detect_paths(font_paths, previous_index)
      updated_index.tap do |index|
        save_index(index) if changed?(updated_index, previous_index)
      end
    end

    def changed?(this, other)
      this.map { |x| x[:path] }.uniq.sort != other.map { |x| x[:path] }.uniq.sort
    end

    def load_system_index
      index = File.exist?(Fontist.system_index_path) ? YAML.load_file(Fontist.system_index_path) : []

      index.each do |item|
        missing_keys = %i[path full_name family_name type] - item.keys
        unless missing_keys.empty?
          raise(Errors::FontIndexCorrupted, <<~MSG.chomp)
            Font index is corrupted.
            Item #{item.inspect} misses required attributes: #{missing_keys.join(', ')}.
            You can remove the index file (#{Fontist.system_index_path}) and try again.
          MSG
        end
      end

      index
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
      file = TTFunk::File.open(path)
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
    end

    def parse_font(file, path)
      x = file.name

      {
        path: path,
        full_name: english_name(x.font_name),
        family_name: english_name(family_name(x)),
        type: english_name(type(x)),
      }
    end

    def name_string(x)
      "P: #{x.platform_id}, E: #{x.encoding_id}, L: #{x.language_id}, #{x.strip_extended}"
    end

    def family_name(x)
      if Fontist.default_families?
        x.font_family.first
      else
        x.preferred_family.first || x.font_family.first
      end
    end

    def type(x)
      if Fontist.default_families?
        x.font_subfamily.first
      else
        x.preferred_subfamily.first || x.font_subfamily.first
      end
    end

    def english_name(name)
      visible_characters(find_english(name))
    end

    def find_english(name)
      name.each do |string|
        return string if string.platform_id == PLATFORM_MICROSOFT &&
                         string.encoding_id == ENCODING_MS_UNICODE_BMP &&
                         string.language_id == LANGUAGE_MS_ENGLISH_AMERICAN
      end

      name.each do |string|
        return string if string.platform_id == PLATFORM_MACINTOSH &&
                         string.encoding_id == ENCODING_MAC_ROMAN &&
                         string.language_id == LANGUAGE_MAC_ENGLISH
      end

      name.last
    end

    def visible_characters(text)
      text.gsub(/[^[:print:]]/, "").to_s
    end

    def save_index(index)
      dir = File.dirname(Fontist.system_index_path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.write(Fontist.system_index_path, YAML.dump(index))
    end
  end
end
