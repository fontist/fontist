require "ttfunk"

module Fontist
  class SystemIndex
    attr_reader :font_paths

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

    private

    def system_index
      @system_index ||= build_system_index
    end

    def build_system_index
      previous_index = load_system_index
      updated_index = detect_paths(font_paths, previous_index)
      updated_index.tap do |index|
        save_index(index)
      end
    end

    def load_system_index
      index = File.exist?(Fontist.system_index_path) ? YAML.load_file(Fontist.system_index_path) : []
      index.group_by { |x| x[:path] }
    end

    def detect_paths(paths, indexed)
      paths.flat_map do |path|
        next indexed[path] if indexed[path]

        detect_fonts(path)
      end
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
        full_name: parse_text(x.font_name.first),
        family_name: parse_text(x.preferred_family.first || x.font_family.first),
        type: parse_text(x.preferred_subfamily.first || x.font_subfamily.first),
      }
    end

    def parse_text(text)
      text.gsub(/[^[:print:]]/, "").to_s
    end

    def save_index(index)
      dir = File.dirname(Fontist.system_index_path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.write(Fontist.system_index_path, YAML.dump(index))
    end
  end
end
