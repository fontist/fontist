require_relative "font_file"
require_relative "collection_file"

module Fontist
  # {:path=>"/Library/Fonts/Arial Unicode.ttf",
  # :full_name=>"Arial Unicode MS",
  # :family_name=>"Arial Unicode MS",
  # :preferred_family_name=>"Arial",
  # :preferred_subfamily=>"Regular",
  # :subfamily=>"Regular"},
  class SystemIndexFont < Lutaml::Model::Serializable
    attribute :path, :string
    attribute :full_name, :string
    attribute :family_name, :string
    attribute :preferred_family_name, :string
    attribute :preferred_subfamily, :string
    attribute :subfamily, :string
    alias :type :subfamily

    key_value do
      map "path", to: :path
      map "full_name", to: :full_name
      map "family_name", to: :family_name
      map "type", to: :subfamily
      map "preferred_family_name", to: :preferred_family_name
      map "preferred_subfamily", to: :preferred_subfamily
    end
  end

  class SystemIndexFontCollection < Lutaml::Model::Collection
    instances :fonts, SystemIndexFont
    attr_accessor :path, :paths_loader

    key_value do
      map_instances to: :fonts
    end

    def set_path(path)
      @path = path
    end

    def set_path_loader(paths_loader)
      @paths_loader = paths_loader
    end

    def self.from_file(path:, paths_loader:)
      # If the file does not exist, return a new collection
      return new.set_content(path, paths_loader) unless File.exist?(path)

      from_yaml(File.read(path)).set_content(path, paths_loader)
    end

    def set_content(path, paths_loader)
      tap do |content|
        content.set_path(path)
        content.set_path_loader(paths_loader)
      end
    end

    ALLOWED_KEYS = %i[path full_name family_name type].freeze

    # Check if the content has all required keys
    def check_index
      Fontist.formulas_repo_path_exists!

      Array(fonts).each do |font|
        missing_keys = ALLOWED_KEYS.reject do |key|
          font.send(key)
        end

        raise_font_index_corrupted(font, missing_keys) if missing_keys.any?
      end
    end

    def to_file(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, to_yaml)
    end

    def find(font, style)
      found_fonts = index.select do |file|
        file.family_name.casecmp?(font) &&
          (style.nil? || file.type.casecmp?(style))
      end

      found_fonts.empty? ? nil : found_fonts
    end

    def index
      return fonts unless index_changed?

      build
      check_index

      fonts
    end

    def index_changed?
      fonts.nil? || fonts.empty? || font_paths != (@paths_loader&.call || []).sort.uniq  
    end

    def update
      tap do |col|
        col.fonts = detect_paths(@paths_loader&.call || [])
      end
    end

    def build(forced: false)
      previous_index = load_index
      updated_fonts = update
      if forced || changed?(updated_fonts, previous_index.fonts || [])
        to_file(@path)
      end

      self
    end

    def rebuild
      build(forced: true)
    end

    private

    def load_index
      index = self.class.from_file(path: @path, paths_loader: @paths_loader)
      index.check_index
      index
    end

    def font_paths
      fonts.map(&:path).uniq.sort
    end

    def changed?(this_fonts, that_fonts)
      this_fonts.map(&:path).uniq.sort != that_fonts.map(&:path).uniq.sort
    end

    def detect_paths(paths)
      # paths are file paths to font files
      paths.sort.uniq.flat_map do |path|
        detect_fonts(path)
      end.compact
    end

    def detect_fonts(path)
      return if excluded?(path)

      gather_fonts(path)
    rescue Errors::FontFileError => e
      print_recognition_error(e, path)
    end

    def excluded?(path)
      excluded_fonts.include?(File.basename(path))
    end

    def excluded_fonts
      @excluded_fonts ||= YAML.load_file(Fontist.excluded_fonts_path)
    end

    def gather_fonts(path)
      case File.extname(path).gsub(/^\./, "").downcase
      when "ttf", "otf"
        detect_file_font(path)
      when "ttc"
        detect_collection_fonts(path)
      else
        print_recognition_error(Errors::UnknownFontTypeError.new(path), path)
      end
    end

    def print_recognition_error(exception, path)
      Fontist.ui.error(<<~MSG.chomp)
        #{exception.inspect}
        Warning: File at #{path} not recognized as a font file.
      MSG
      nil
    end

    def detect_file_font(path)
      font_file = FontFile.from_path(path)

      parse_font(font_file, path)
    end

    def detect_collection_fonts(path)
      CollectionFile.from_path(path) do |collection|
        collection.map do |font_file|
          parse_font(font_file, path)
        end
      end
    end

    def parse_font(font_file, path)
      SystemIndexFont.new(
        path: path,
        full_name: font_file.full_name,
        family_name: font_file.family,
        subfamily: font_file.subfamily,
        preferred_family_name: font_file.preferred_family,
        preferred_subfamily_name: font_file.preferred_subfamily,
      )
    end

    def raise_font_index_corrupted(font, missing_keys)
      raise(Errors::FontIndexCorrupted, <<~MSG.chomp)
        Font index is corrupted.
        Item #{font.inspect} misses required attributes: #{missing_keys.join(', ')}.
        You can remove the index file (#{@path}) and try again.
      MSG
    end
  end

  class SystemIndex
    include Utils::Locking

    def self.system_index
      @system_index = SystemIndexFontCollection.from_file(
        path: Fontist.system_index_path,
        paths_loader: -> { SystemFont.font_paths },
      )
    end

    def self.fontist_index
      @fontist_index = SystemIndexFontCollection.from_file(
        path: Fontist.fontist_index_path,
        paths_loader: -> { SystemFont.fontist_font_paths },
      )
    end

    # def build_index
    #   lock(lock_path) do
    #     do_build_index
    #   end
    # end

    # def lock_path
    #   Utils::Cache.lock_path(@index_path)
    # end
  end
end
