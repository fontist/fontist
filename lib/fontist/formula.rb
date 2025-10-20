require "lutaml/model"
require_relative "font_model"
require_relative "font_collection"
require_relative "extract"
require_relative "index"
require_relative "helpers"
require_relative "update"
require "git"

module Fontist
  require "lutaml/model"

  class Resource < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :source, :string
    attribute :urls, :string, collection: true
    attribute :sha256, :string, collection: true
    attribute :file_size, :integer
    attribute :family, :string
    attribute :files, :string, collection: true

    def empty?
      Array(urls).empty? && Array(files).empty?
    end
  end

  class ResourceCollection < Lutaml::Model::Collection
    instances :resources, Resource

    key_value do
      root "resources"
      map to: :resources
      map_key to_instance: :name
    end

    def empty?
      resources.nil? || Array(resources).all?(&:empty?)
    end
  end

  class Formula < Lutaml::Model::Serializable
    NAMESPACES = {
      "sil" => "SIL",
      "macos" => "macOS",
    }.freeze

    attribute :name, :string
    attribute :path, :string
    attribute :description, :string
    attribute :homepage, :string
    attribute :display_progress_bar, :boolean
    attribute :repository, :string
    attribute :copyright, :string
    attribute :license_url, :string
    attribute :open_license, :string
    attribute :requires_license_agreement, :string
    attribute :platforms, :string, collection: true
    attribute :min_fontist, :string
    attribute :digest, :string
    attribute :instructions, :string
    attribute :resources, ResourceCollection, collection: true
    attribute :font_collections, FontCollection, collection: true
    attribute :fonts, FontModel, collection: true, default: []
    attribute :extract, Extract, collection: true
    attribute :command, :string

    key_value do
      map "name", to: :name
      map "description", to: :description
      map "homepage", to: :homepage
      map "display_progress_bar", to: :display_progress_bar
      map "repository", to: :repository
      map "platforms", to: :platforms
      map "resources", to: :resources, value_map: {
        to: { empty: :empty, omitted: :omitted, nil: :nil },
      }
      map "digest", to: :digest
      map "instructions", to: :instructions
      map "font_collections", to: :font_collections
      map "fonts", to: :fonts
      map "extract", to: :extract, value_map: {
        to: { empty: :empty, omitted: :omitted, nil: :nil },
      }
      map "min_fontist", to: :min_fontist
      map "copyright", to: :copyright
      map "requires_license_agreement", to: :requires_license_agreement
      map "license_url", to: :license_url
      map "open_license", to: :open_license
      map "command", to: :command
    end

    def self.update_formulas_repo
      Update.call
    end

    def self.all
      formulas = Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
        Formula.from_file(path)
      end

      FormulaCollection.new(formulas)
    end

    def self.all_keys
      Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
        path.sub("#{Fontist.formulas_path}/", "").sub(".yml", "")
      end
    end

    def self.find(font_name)
      Indexes::FontIndex.from_file.load_formulas(font_name).first
    end

    def self.find_many(font_name)
      Indexes::FontIndex.from_file.load_formulas(font_name)
    end

    def self.find_fonts(font_name)
      formulas = Indexes::FontIndex.from_file.load_formulas(font_name)

      formulas.map do |formula|
        formula.all_fonts.select do |f|
          f.name.casecmp?(font_name)
        end
      end.flatten
    end

    def self.find_styles(font_name, style_name)
      formulas = Indexes::FontIndex.from_file.load_formulas(font_name)

      formulas.map do |formula|
        formula.all_fonts.map do |f|
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

      from_file(path)
    end

    def self.find_by_name(name)
      key = name_to_key(name)

      find_by_key(key)
    end

    def self.name_to_key(name)
      name.downcase.gsub(" ", "_")
    end

    def self.find_by_font_file(font_file)
      key = Indexes::FilenameIndex.from_file
        .load_index_formulas(File.basename(font_file))
        .flat_map(&:name)
        .first

      find_by_key(key)
    end

    def self.from_file(path)
      unless File.exist?(path)
        raise Fontist::Errors::FormulaCouldNotBeFoundError,
              "Formula file not found: #{path}"
      end

      content = File.read(path)

      from_yaml(content).tap do |formula|
        formula.path = path
        formula.name = titleize(formula.key_from_path) if formula.name.nil?
      end
    end

    def self.titleize(str)
      str.split("/").map do |part|
        part.tr("_", " ").split.map(&:capitalize).join(" ")
      end.join("/")
    end

    def manual?
      !downloadable?
    end

    def downloadable?
      !resources.nil? && !resources.empty?
    end

    def source
      return nil if resources.empty?

      resources.first.source
    end

    def key
      @key ||= key_from_path
    end

    def key_from_path
      return "" unless @path

      escaped = Regexp.escape("#{Fontist.formulas_path}/")
      @path.sub(Regexp.new("^#{escaped}"), "").sub(/\.yml$/, "").to_s
    end

    def license
      open_license || requires_license_agreement
    end

    def license_required?
      requires_license_agreement ? true : false
    end

    def file_size
      return nil if resources.nil? || resources.empty?

      resources.first.file_size
    end

    def font_by_name(name)
      all_fonts.find do |font|
        font.name.casecmp?(name)
      end
    end

    def fonts_by_name(name)
      all_fonts.select do |font|
        font.name.casecmp?(name)
      end
    end

    def all_fonts
      Array(fonts) + collection_fonts
    end

    def collection_fonts
      Array(font_collections).flat_map do |c|
        c.fonts.flat_map do |f|
          f.styles.each do |s|
            s.font = c.filename
            s.source_font = c.source_filename
          end
          f
        end
      end
    end

    def style_override(font)
      all_fonts
        .map(&:styles)
        .flatten
        .detect { |s| s.family_name == font }&.override || {}
    end

    private

    def real_path
      Dir.glob(path).first
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

    def fonts_by_family(data)
      return hash_all_fonts(data) unless Fontist.preferred_family?

      preferred_family_fonts(data)
    end

    def preferred_family_fonts(data)
      groups = preferred_family_styles(data).group_by do |style|
        style["family_name"]
      end

      groups.map do |font_name, font_styles|
        { "name" => font_name, "styles" => font_styles }
      end
    end

    def preferred_family_styles(data)
      hash_all_fonts(data).flat_map do |font|
        font["styles"].map do |style|
          style.merge(preferred_style(style))
        end
      end
    end

    def preferred_style(style)
      {
        "family_name" => style["preferred_family_name"] || style["family_name"],
        "type" => style["preferred_type"] || style["type"],
        "default_family_name" => style["family_name"],
        "default_type" => style["type"],
      }
    end

    def hash_all_fonts(data)
      hash_collection_fonts(data) + hash_fonts(data)
    end

    def hash_collection_fonts(data)
      return [] unless data["font_collections"]

      data["font_collections"].flat_map do |coll|
        filenames = { "font" => coll["filename"],
                      "source_font" => coll["source_filename"] }

        coll["fonts"].map do |font|
          font.merge("styles" => font["styles"].map { |s| filenames.merge(s) })
        end
      end
    end

    def hash_fonts(data)
      return [] unless data["fonts"]

      data["fonts"]
    end
  end

  class FormulaCollection < Lutaml::Model::Collection
    instances :formulas, Formula

    key_value do
      map "name", to: :name
      map "formula", to: :formula
    end
  end
end
