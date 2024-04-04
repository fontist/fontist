require "fontist/index"
require "fontist/helpers"
require "fontist/update"
require "git"

module Fontist
  class Formula
    NAMESPACES = {
      "sil" => "SIL",
      "macos" => "macOS",
    }.freeze

    def self.update_formulas_repo
      Update.call
    end

    def self.all
      Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
        Formula.new_from_file(path)
      end
    end

    def self.all_keys
      Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
        path.sub("#{Fontist.formulas_path}/", "").sub(".yml", "")
      end
    end

    def self.find(font_name)
      Indexes::FontIndex.from_yaml.load_formulas(font_name).first
    end

    def self.find_many(font_name)
      Indexes::FontIndex.from_yaml.load_formulas(font_name)
    end

    def self.find_fonts(font_name)
      formulas = Indexes::FontIndex.from_yaml.load_formulas(font_name)

      formulas.map do |formula|
        formula.fonts.select do |f|
          f.name.casecmp?(font_name)
        end
      end.flatten
    end

    def self.find_styles(font_name, style_name)
      formulas = Indexes::FontIndex.from_yaml.load_formulas(font_name)

      formulas.map do |formula|
        formula.fonts.map do |f|
          f.styles.select do |s|
            f.name.casecmp?(font_name) && s.type.casecmp?(style_name)
          end
        end
      end.flatten
    end

    def self.find_by_key_or_name(name)
      find_by_key(name) || find_by_name(name)
    end

    def self.find_by_key(key)
      path = Fontist.formulas_path.join("#{key}.yml")
      return unless File.exist?(path)

      new_from_file(path)
    end

    def self.find_by_name(name)
      key = name_to_key(name)

      find_by_key(key)
    end

    def self.name_to_key(name)
      name.downcase.gsub(" ", "_")
    end

    def self.find_by_font_file(font_file)
      key = Indexes::FilenameIndex
        .from_yaml
        .load_index_formulas(File.basename(font_file))
        .map(&:name)
        .first

      find_by_key(key)
    end

    def self.new_from_file(path)
      data = YAML.load_file(path)
      new(data, path)
    end

    def initialize(data, path)
      @data = data
      @path = real_path(path)
    end

    def to_index_formula
      Indexes::IndexFormula.new(path)
    end

    def manual?
      !downloadable?
    end

    def downloadable?
      @data.key?("resources")
    end

    def source
      return unless @data["resources"]

      @data["resources"].values.first["source"]
    end

    def path
      @path
    end

    def key
      @key ||= {}
      @key[@path] ||= key_from_path
    end

    def name
      @name ||= {}
      @name[key] ||= namespace.empty? ? base_name : "#{namespace}/#{base_name}"
    end

    def description
      @data["description"]
    end

    def homepage
      @data["homepage"]
    end

    def copyright
      @data["copyright"]
    end

    def license_url
      @data["license_url"]
    end

    def license
      @data["open_license"] || @data["requires_license_agreement"]
    end

    def license_required
      @data["requires_license_agreement"] ? true : false
    end

    def platforms
      @data["platforms"]
    end

    def min_fontist
      @data["min_fontist"]
    end

    def extract
      Helpers.parse_to_object(@data["extract"])
    end

    def file_size
      return unless @data["resources"]

      @data["resources"].values.first["file_size"]&.to_i
    end

    def resources
      Helpers.parse_to_object(@data["resources"]&.values)
    end

    def instructions
      @data["instructions"]
    end

    def font_by_name(name)
      fonts.find do |font|
        font.name.casecmp?(name)
      end
    end

    def fonts_by_name(name)
      fonts.select do |font|
        font.name.casecmp?(name)
      end
    end

    def fonts
      @fonts ||= Helpers.parse_to_object(fonts_by_family)
    end

    def digest
      @data["digest"]
    end

    def style_override(font)
      fonts
        .map(&:styles)
        .flatten
        .detect { |s| s.family_name == font }
        &.dig(:override) || {}
    end

    private

    def real_path(path)
      Dir.glob(path).first
    end

    def key_from_path
      escaped = Regexp.escape("#{Fontist.formulas_path}/")
      @path.sub(Regexp.new("^#{escaped}"), "").sub(/\.yml$/, "").to_s
    end

    def namespace
      namespace_from_mappings || namespace_from_key
    end

    def namespace_from_mappings
      parts = key.split("/")
      namespace_from_key = parts.take(parts.size - 1).join("/")
      NAMESPACES[namespace_from_key]
    end

    def namespace_from_key
      parts = key.downcase.gsub("_", " ").split("/")
      parts.take(parts.size - 1).map do |namespace|
        namespace.split.map(&:capitalize).join(" ")
      end.join("/")
    end

    def base_name
      @data["name"] || base_name_from_key
    end

    def base_name_from_key
      key.split("/").last
        .downcase.gsub("_", " ")
        .split.map(&:capitalize).join(" ")
    end

    def fonts_by_family
      return hash_all_fonts unless Fontist.preferred_family?

      preferred_family_fonts
    end

    def preferred_family_fonts
      groups = preferred_family_styles.group_by do |style|
        style["family_name"]
      end

      groups.map do |font_name, font_styles|
        { "name" => font_name, "styles" => font_styles }
      end
    end

    def preferred_family_styles
      hash_all_fonts.flat_map do |font|
        font["styles"].map do |style|
          style.merge(preferred_style(style))
        end
      end
    end

    def preferred_style(style)
      { "family_name" => style["preferred_family_name"] || style["family_name"],
        "type" => style["preferred_type"] || style["type"],
        "default_family_name" => style["family_name"],
        "default_type" => style["type"] }
    end

    def hash_all_fonts
      hash_collection_fonts + hash_fonts
    end

    def hash_collection_fonts
      return [] unless @data["font_collections"]

      @data["font_collections"].flat_map do |coll|
        filenames = { "font" => coll["filename"],
                      "source_font" => coll["source_filename"] }

        coll["fonts"].map do |font|
          font.merge("styles" => font["styles"].map { |s| filenames.merge(s) })
        end
      end
    end

    def hash_fonts
      return [] unless @data["fonts"]

      @data["fonts"]
    end
  end
end
