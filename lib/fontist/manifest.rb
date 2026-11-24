require "lutaml/model"
require_relative "format_matcher"
require_relative "format_spec"

module Fontist
  class ManifestFont < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :styles, :string, collection: true

    # Format specification (if not available, will transcode using Fontisan)
    attribute :format, :string
    attribute :variable_axes, :string, collection: true
    attribute :prefer_variable, :boolean, default: false
    attribute :variable, :boolean
    attribute :all_variants, :boolean, default: false

    # Transcoding options
    attribute :transcode_path, :string
    attribute :keep_original, :boolean, default: true

    # Collection options
    attribute :collection_index, :integer

    # Font operations (subsetting, conversion failure handling)
    attribute :subset_unicodes, :string
    attribute :subset_text, :string
    attribute :fallback_to_original, :boolean, default: false
    attribute :instance, :string

    # Build FormatSpec from attributes
    def format_spec
      FormatSpec.new(
        format: format,
        variable_axes: variable_axes,
        prefer_variable: prefer_variable,
        variable: variable,
        all_variants: all_variants,
        transcode_path: transcode_path,
        keep_original: keep_original,
        collection_index: collection_index,
        subset_unicodes: subset_unicodes,
        subset_text: subset_text,
        fallback_to_original: fallback_to_original,
        instance: instance,
      )
    end

    def style_paths(locations: false)
      ary = Array(styles)
      (ary.empty? ? [nil] : ary).flat_map do |style|
        find_font_with_name(name, style).tap do |x|
          raise Errors::MissingFontError.new(name, style) if x.nil? && locations
        end
      end.compact
    end

    def group_paths(locations: false)
      style_paths(locations: locations).group_by(&:type)
        .transform_values { |group| style(group) }
    end

    def style(styles_ary)
      { "full_name" => styles_ary.first.full_name,
        "paths" => styles_ary.filter_map(&:path) }
    end

    def find_font_with_name(font, style)
      Fontist::SystemFont.find_styles(font, style)
    end

    # True when every located file fails the font's static/variant spec —
    # e.g. only a variable font's named instance resolves a variable: false
    # request — so installation must fetch files that actually match.
    # With the static default, variable files on disk also do not satisfy a
    # plain request when the formula offers static files: stale variable
    # installs from older fontist versions would otherwise shadow the
    # statics forever.
    def unsatisfied_by_spec?
      located = style_paths
      return true if located.empty?

      return true if static_default_shadowed_by_variable?(located)

      return false unless format_spec.has_constraints?

      matcher = FormatMatcher.new(format_spec)
      located.all? { |indexed| !matcher.matches_indexed_font?(indexed) }
    end

    def static_default_shadowed_by_variable?(located)
      return false if format_spec.variable_requested?
      return false if format_spec.all_variants

      located.all? { |indexed| indexed.variable_font } &&
        located.any? { |indexed| indexed.variable_font } &&
        Fontist::Formula.offers_static_variant?(name)
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false,
               location: nil)
      validate_location_parameter!(location)
      validate_platform_compatibility!

      Fontist::Font.install(
        name,
        force: true,
        confirmation: confirmation,
        hide_licenses: hide_licenses,
        no_progress: no_progress,
        location: location,
        format_spec: format_spec,
      )
    rescue Fontist::Errors::PlatformMismatchError => e
      # Re-raise with clear context for manifest users
      Fontist.ui.error(e.message)
      raise
    end

    def to_response(locations: false)
      groups = group_paths(locations: locations)

      return self if groups.empty?

      ManifestResponseFont.new(
        name: name,
        styles: groups.map do |type, details|
          ManifestResponseFontStyle.new(
            type: type,
            full_name: details["full_name"],
            paths: details["paths"],
          )
        end,
      )
    end

    def group_paths_empty?
      group_paths.compact.empty?
    end

    private

    def validate_location_parameter!(location)
      return unless location
      return if location.is_a?(Symbol)

      raise ArgumentError,
            "location must be a Symbol (e.g., :fontist, :user, :system), got #{location.class}"
    end

    def validate_platform_compatibility!
      formula = Fontist::Formula.find_many(name)
      return if formula.empty?
      return if formula.any?(&:compatible_with_platform?)

      raise Fontist::Errors::PlatformMismatchError.new(
        name,
        formula.map(&:platforms).flatten.uniq,
        Fontist::Utils::System.user_os,
      )
    end
  end

  # Manifest class for managing font manifests.
  class Manifest < Lutaml::Model::Collection
    instances :fonts, ManifestFont

    # TODO: Re-enable these when
    key_value do
      map to: :fonts, root_mappings: {
        name: :key,
        styles: :value,
      }
    end

    # Font options a manifest entry can carry next to its styles:
    #
    #   Roboto:
    #     styles: [Regular, Bold]
    #     format: woff2
    #
    # The plain form `Roboto: [Regular, Bold]` stays valid.
    FONT_OPTIONS = %w[format variable_axes prefer_variable variable
                      all_variants transcode_path
                      keep_original collection_index subset_unicodes
                      subset_text fallback_to_original instance].freeze

    def self.from_yaml(content, options = {})
      data = YAML.safe_load(content)
      return super unless data.is_a?(Hash) && data.values.any?(Hash)

      plain, font_options = split_font_options(data)
      super(plain.to_yaml, options).tap do |manifest|
        manifest.apply_font_options(font_options)
      end
    end

    def self.split_font_options(data)
      font_options = {}
      plain = data.to_h do |name, value|
        next [name, value] unless value.is_a?(Hash)

        font_options[name] = font_options_of(name, value)
        [name, value["styles"] || value[:styles]]
      end
      [plain, font_options]
    end

    def self.font_options_of(name, value)
      value = value.transform_keys(&:to_s)
      unknown = value.keys - FONT_OPTIONS - ["styles"]
      unless unknown.empty?
        raise Fontist::Errors::ManifestCouldNotBeReadError,
              "Unknown option(s) for '#{name}': #{unknown.join(', ')}"
      end

      value.slice(*FONT_OPTIONS)
    end

    def apply_font_options(font_options)
      Array(fonts).each do |font|
        font_options.fetch(font.name, {}).each do |key, value|
          font.public_send(:"#{key}=", value)
        end
      end
    end

    def self.from_file(path, locations: false)
      Fontist.ui.debug("Manifest: #{path}")

      manifest_model = model_from_file(path)

      # Use performance optimizations for faster manifest compilation
      with_performance_optimizations do
        manifest_model.to_response(locations: locations)
      end
    end

    # The parsed manifest model with per-font options intact — from_file
    # collapses resolved fonts into a response whose entries have lost
    # them, so install flows that honor variable:/all_variants: must
    # start here instead.
    def self.model_from_file(path)
      validate_manifest_path!(path)

      begin
        from_yaml(File.read(path).strip)
      rescue StandardError => e
        raise Fontist::Errors::ManifestCouldNotBeReadError,
              "Manifest file could not be read: #{e.message}"
      end
    end

    def self.validate_manifest_path!(path)
      unless File.exist?(path)
        raise Fontist::Errors::ManifestCouldNotBeFoundError,
              "Manifest file not found: #{path}"
      end

      return unless File.read(path).strip.empty?

      raise Fontist::Errors::ManifestCouldNotBeReadError,
            "Manifest file is empty: #{path}"
    end

    def self.from_hash(data, options = {})
      locations = options.delete(:locations) || false
      data, font_options = split_font_options(data) if data.is_a?(Hash)

      model = super
      model.apply_font_options(font_options) if font_options

      # Use performance optimizations for faster manifest compilation
      with_performance_optimizations do
        model.to_response(locations: locations)
      end
    end

    # Enable performance optimizations for manifest compilation
    # This includes:
    # - Read-only mode for indexes (skip index_changed? checks)
    # - Caching of find_styles results to avoid repeated lookups
    def self.with_performance_optimizations
      # Enable read-only mode on all indexes to skip index_changed? checks
      Fontist::Indexes::FontistIndex.instance.read_only_mode
      Fontist::Indexes::UserIndex.instance.read_only_mode
      Fontist::Indexes::SystemIndex.instance.read_only_mode

      # Enable caching for find_styles lookups
      Fontist::SystemFont.enable_find_styles_cache

      yield
    ensure
      # Always restore normal mode after the operation so the read-only flag
      # does not leak across calls and turn the singletons effectively stale.
      Fontist::Indexes::FontistIndex.instance.disable_read_only_mode
      Fontist::Indexes::UserIndex.instance.disable_read_only_mode
      Fontist::Indexes::SystemIndex.instance.disable_read_only_mode
      Fontist::SystemFont.disable_find_styles_cache
    end

    def self.font_class
      ManifestFont
    end

    def fonts_casted
      Array(fonts).map do |font|
        self.class.font_class === font ? font : self.class.font_class.new(font.to_h)
      end
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false,
location: nil)
      installed_any = false
      fonts_casted.each do |font|
        paths = font.group_paths

        if paths.empty? || font.unsatisfied_by_spec?
          font.install(confirmation: confirmation,
                       hide_licenses: hide_licenses,
                       no_progress: no_progress,
                       location: location)
          installed_any = true
        end
      end
      if installed_any
        Fontist::SystemFont.reset_fontist_font_paths_cache
        Fontist::SystemFont.reset_find_styles_cache
      end
      to_response
    end

    def to_response(locations: false)
      return self if fonts_casted.any?(&:group_paths_empty?) && !locations

      # Use performance optimizations for faster manifest compilation
      self.class.with_performance_optimizations do
        ManifestResponse.new.tap do |response|
          response.fonts = fonts_casted.map do |font|
            font.to_response(locations: locations)
          end
        end
      end
    end

    def to_file(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, to_yaml)
    end
  end
end
