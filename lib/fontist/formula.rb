require "fontist/index"
require "fontist/helpers"
require "fontist/update"
require "git"

module Fontist
  class Formula
    def self.update_formulas_repo
      Update.call
    end

    def self.all
      Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
        Formula.new_from_file(path)
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

    def self.new_from_file(path)
      data = YAML.load_file(path)
      new(data, path)
    end

    def initialize(data, path)
      @data = data
      @path = path
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

    def path
      @path
    end

    def key
      @data["key"] || default_key
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

    def extract
      Helpers.parse_to_object(@data["extract"])
    end

    def resources
      Helpers.parse_to_object(@data["resources"]&.values)
    end

    def instructions
      @data["instructions"]
    end

    def fonts
      @fonts ||= Helpers.parse_to_object(hash_collection_fonts + hash_fonts)
    end

    def digest
      @data["digest"]
    end

    private

    def default_key
      escaped = Regexp.escape(Fontist.formulas_path.to_s + "/")
      @path.sub(Regexp.new("^" + escaped), "").sub(/\.yml$/, "")
    end

    def hash_collection_fonts
      return [] unless @data["font_collections"]

      @data["font_collections"].flat_map do |coll|
        filenames = { "font" => coll["filename"],
                      "source_font" => coll["source_filename"] }

        coll["fonts"].map do |font|
          { "name" => font["name"],
            "styles" => font["styles"].map { |s| filenames.merge(s) } }
        end
      end
    end

    def hash_fonts
      return [] unless @data["fonts"]

      @data["fonts"]
    end
  end
end
