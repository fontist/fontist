require "lutaml/model"
require_relative "resource_collection"
require_relative "font_collection"
require_relative "font_model"
require_relative "extract"
require_relative "index"
require_relative "helpers"
require_relative "update"
require_relative "import_source"
require_relative "macos_import_source"
require_relative "google_import_source"
require_relative "sil_import_source"
require_relative "format_matcher"
require "git"

module Fontist
  # Formula - v5 schema with multi-format font support
  #
  # This class handles formulas with schema_version 5, which supports:
  # - Multiple font formats (TTF, WOFF2, variable fonts)
  # - Format metadata on resources
  # - Variable axes for variable font filtering
  #
  # For v4 formulas, use the migration script to convert to v5 format.
  #
  class Formula < Lutaml::Model::Serializable
    NAMESPACES = {
      "sil" => "SIL",
      "macos" => "macOS",
    }.freeze

    # v5 schema version
    attribute :schema_version, :integer, default: 5

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
    attribute :import_source, ImportSource, polymorphic: [
      "MacosImportSource",
      "GoogleImportSource",
      "SilImportSource",
    ]
    attribute :font_version, :string

    key_value do
      map "schema_version", to: :schema_version
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
      map "import_source", to: :import_source, polymorphic: {
        attribute: :type,
        class_map: {
          "macos" => "Fontist::MacosImportSource",
          "google" => "Fontist::GoogleImportSource",
          "sil" => "Fontist::SilImportSource",
        },
      }
      map "font_version", to: :font_version
    end

    class << self
      def update_formulas_repo
        Update.call
      end

      def all
        formulas = Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
          Formula.from_file(path)
        end.compact

        FormulaCollection.new(formulas)
      end

      def all_keys
        Dir[Fontist.formulas_path.join("**/*.yml").to_s].map do |path|
          path.sub("#{Fontist.formulas_path}/", "").sub(".yml", "")
        end
      end

      def find(font_name)
        Indexes::FontIndex.from_file.load_formulas(font_name).first
      end

      def find_many(font_name)
        Indexes::FontIndex.from_file.load_formulas(font_name)
      end

      def find_fonts(font_name)
        formulas = Indexes::FontIndex.from_file.load_formulas(font_name)

        formulas.map do |formula|
          formula.all_fonts.select do |f|
            f.name.casecmp?(font_name)
          end
        end.flatten
      end

      def find_styles(font_name, style_name)
        formulas = Indexes::FontIndex.from_file.load_formulas(font_name)

        formulas.map do |formula|
          formula.all_fonts.map do |f|
            f.styles.select do |s|
              f.name.casecmp?(font_name) && s.type.casecmp?(style_name)
            end
          end
        end.flatten
      end

      def find_by_key_or_name(name)
        find_by_key(name) || find_by_name(name)
      end

      def find_by_key(key)
        path = Fontist.formulas_path.join("#{key}.yml")
        return unless File.exist?(path)

        from_file(path)
      end

      def find_by_name(name)
        key = name_to_key(name)

        find_by_key(key)
      end

      def name_to_key(name)
        name.downcase.gsub(" ", "_")
      end

      def find_by_font_file(font_file)
        key = Indexes::FilenameIndex.from_file
          .load_index_formulas(File.basename(font_file))
          .flat_map(&:name)
          .first

        find_by_key(key)
      end

      def from_file(path)
        unless File.exist?(path)
          raise Fontist::Errors::FormulaNotFoundError,
                "Formula file not found: #{path}"
        end

        content = File.read(path)

        from_yaml(content).tap do |formula|
          formula.path = path
          formula.name = titleize(formula.key_from_path) if formula.name.nil?
        end
      rescue Lutaml::Model::Error, TypeError, ArgumentError => e
        Fontist.ui.error("WARN: Could not load formula #{path}: #{e.message}")
        nil
      end

      def titleize(str)
        str.split("/").map do |part|
          part.tr("_", " ").split.map(&:capitalize).join(" ")
        end.join("/")
      end
    end

    # v5 formulas always have schema_version 5
    def v5?
      true
    end

    def effective_schema_version
      5
    end

    # Filter resources based on format specification
    def matching_resources(format_spec)
      return resources if format_spec.nil?

      FormatMatcher.new(format_spec).filter_resources(resources)
    end

    def manual?
      !downloadable?
    end

    def downloadable?
      !resources.nil? && !resources.empty?
    end

    def macos_import?
      import_source.is_a?(MacosImportSource)
    end

    def google_import?
      import_source.is_a?(GoogleImportSource)
    end

    def sil_import?
      import_source.is_a?(SilImportSource)
    end

    def manual_formula?
      import_source.nil?
    end

    def compatible_with_current_platform?
      return true unless macos_import?

      current_macos = Utils::System.macos_version
      return true unless current_macos

      import_source.compatible_with_macos?(current_macos)
    end

    def source
      return nil if resources.empty?

      resources.first.source
    end

    def compatible_with_platform?(platform = nil)
      target = platform || Utils::System.user_os.to_s

      # No platform restrictions = compatible with all
      return true if platforms.nil? || platforms.empty?

      # Check if platform matches - support both exact matches and prefixed matches
      platform_matches = platforms.any? do |p|
        p == target || p.start_with?("#{target}-")
      end

      return false unless platform_matches

      # For macOS platform-tagged formulas, check framework support
      if target == "macos" && macos_import?
        current_macos = Utils::System.macos_version
        return true unless current_macos

        # Check if framework exists for this macOS version
        framework = Utils::System.catalog_version_for_macos
        if framework.nil?
          require_relative "macos_framework_metadata"
          raise Errors::UnsupportedMacOSVersionError.new(
            current_macos,
            MacosFrameworkMetadata.metadata,
          )
        end

        return import_source.compatible_with_macos?(current_macos)
      end

      true
    end

    def platform_restriction_message
      return nil if compatible_with_platform?

      current = Utils::System.user_os

      message = "Font '#{name}' is only available for: #{platforms.join(', ')}. "
      message += "Your current platform is: #{current}."

      if current == :macos && macos_import?
        current_version = Utils::System.macos_version
        if current_version
          message += " Your macOS version is: #{current_version}."
        end

        min_version = import_source.min_macos_version
        max_version = import_source.max_macos_version

        if min_version && max_version
          message += " This font requires macOS #{min_version} to #{max_version}."
        elsif min_version
          message += " This font requires macOS #{min_version} or later."
        elsif max_version
          message += " This font requires macOS #{max_version} or earlier."
        end
      end

      "#{message} This font cannot be installed on your system."
    end

    def requires_system_installation?
      source == "apple_cdn" && platforms&.include?("macos")
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
  end

  # FormulaCollection holds multiple formulas
  class FormulaCollection < Lutaml::Model::Collection
    instances :formulas, Formula

    key_value do
      map "name", to: :name
      map "formula", to: :formula
    end
  end
end
