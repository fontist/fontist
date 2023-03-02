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

      def transform_override_keys(dict)
        dict
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

      def transform_override_keys(dict)
        mapping = { preferred_family_name: :family_name, preferred_type: :type }
        dict.transform_keys! { |k| mapping[k] }
      end
    end

    PLATFORM_MACINTOSH = 1
    PLATFORM_MICROSOFT = 3

    ENCODING_MAC_ROMAN = 0
    ENCODING_MS_UNICODE_BMP = 1

    LANGUAGE_MAC_ENGLISH = 0
    LANGUAGE_MS_ENGLISH_AMERICAN = 0x409

    ALLOWED_KEYS = %i[path full_name family_name type].freeze

    def self.system_index
      path = if Fontist.preferred_family?
               Fontist.system_preferred_family_index_path
             else
               Fontist.system_index_path
             end

      @system_index ||= {}
      @system_index[Fontist.preferred_family?] ||= {}
      @system_index[Fontist.preferred_family?][path] ||=
        new(path, -> { SystemFont.font_paths }, family)
    end

    def self.fontist_index
      path = if Fontist.preferred_family?
               Fontist.fontist_preferred_family_index_path
             else
               Fontist.fontist_index_path
             end

      @fontist_index ||= {}
      @fontist_index[Fontist.preferred_family?] ||= {}
      @fontist_index[Fontist.preferred_family?][path] ||=
        new(path, -> { SystemFont.fontist_font_paths }, family)
    end

    def self.family
      Fontist.preferred_family? ? PreferredFamily.new : DefaultFamily.new
    end

    def initialize(index_path, font_paths_fetcher, family)
      @index_path = index_path
      @font_paths_fetcher = font_paths_fetcher
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
      return @index unless index_changed?

      @index = build_index
    end

    def index_changed?
      @index.nil? ||
        @index.map { |x| x[:path] }.uniq.sort != font_paths.sort
    end

    def font_paths
      @font_paths_fetcher.call
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

    def changed?(this, that)
      this.map { |x| x[:path] }.uniq.sort != that.map { |x| x[:path] }.uniq.sort
    end

    def load_index
      index = File.exist?(@index_path) ? YAML.load_file(@index_path) : []
      check_index(index)
      index
    end

    def check_index(index)
      index.each do |item|
        missing_keys = ALLOWED_KEYS - item.keys
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
    rescue StandardError
      Fontist.ui.error(<<~MSG.chomp)
        #{$!.message}
        Warning: File at #{path} not recognized as a font file.
      MSG
    end

    def detect_file_font(path)
      content = File.read(path, mode: "rb")
      file = TTFunk::File.new(content)

      parse_font(file, path)
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
      family_name = english_name(@family.family_name(x))

      {
        path: path,
        full_name: english_name(x.font_name),
        family_name: family_name,
        type: english_name(@family.type(x)),
      }.merge(override_font_props(path, family_name))
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

    def override_font_props(path, font_name)
      override = Formula.find_by_font_file(path)
        &.style_override(font_name)&.to_h || {}

      @family.transform_override_keys(override)
        .slice(*ALLOWED_KEYS)
    end

    def save_index(index)
      dir = File.dirname(@index_path)
      FileUtils.mkdir_p(dir)
      File.write(@index_path, YAML.dump(index))
    end
  end
end
