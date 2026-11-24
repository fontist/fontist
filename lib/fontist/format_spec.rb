require "lutaml/model"

module Fontist
  # Encapsulates format requirements for font installation/lookup
  #
  # Supports:
  # - Format selection (install specific format)
  # - Variable axes selection
  # - Automatic transcoding (if format not available, transcode from available)
  # - Transcode destination specification
  #
  # This model is passed through the entire pipeline:
  # CLI -> Font -> FormulaPicker -> FontInstaller -> Index
  class FormatSpec < Lutaml::Model::Serializable
    # Format preference (what format to install)
    # If format not available in formula, will transcode from available format
    attribute :format, :string

    # Variable font selection
    attribute :variable_axes, :string, collection: true
    attribute :prefer_variable, :boolean, default: false

    # Static/variable selection: nil = any, true = variable only,
    # false = static only
    attribute :variable, :boolean

    # Install both static and variable variants in one call (--both)
    attribute :all_variants, :boolean, default: false

    # Format preferences
    attribute :prefer_format, :string

    # Transcoding options (used when format not available)
    attribute :transcode_path, :string
    attribute :keep_original, :boolean, default: true

    # Collection handling
    attribute :collection_index, :integer

    # Subsetting: keep only these characters (U+0020-007E,U+00E9 / literal text)
    attribute :subset_unicodes, :string
    attribute :subset_text, :string

    # Static instance of a variable font: "wght=300,wdth=90"
    attribute :instance, :string

    # Explicit opt-in: install the original format when conversion fails
    attribute :fallback_to_original, :boolean, default: false

    # Convenience constructor for CLI
    def self.from_options(options = {})
      preference = parse_variable_preference(options)
      new(
        format: options[:format],
        variable_axes: parse_variable_axes(options[:variable_axes]),
        prefer_variable: preference.nil? &&
                         (options[:prefer_variable] || false),
        variable: preference,
        all_variants: options[:both] || false,
        prefer_format: options[:prefer_format],
        transcode_path: options[:transcode_path],
        keep_original: options.fetch(:keep_original, true),
        collection_index: options[:collection_index],
        **operation_options(options),
      )
    end

    # Explicit --static/--variable flags win over legacy prefer_variable.
    def self.parse_variable_preference(options)
      return true if options[:variable]
      return false if options[:static]

      nil
    end

    def self.operation_options(options)
      {
        subset_unicodes: options[:subset_unicodes],
        subset_text: options[:subset_text],
        instance: options[:instance],
        fallback_to_original: options[:fallback_to_original] || false,
      }
    end

    def self.parse_variable_axes(value)
      return nil if value.nil?
      return value if value.is_a?(Array)

      value.to_s.split(",").filter_map(&:strip)
    end

    # Check if any format constraints are specified
    def has_constraints?
      !!(format || variable_axes&.any? || prefer_variable ||
         !variable.nil? || all_variants || prefer_format)
    end

    # Check if variable font is requested
    def variable_requested?
      !!(variable == true || variable_axes&.any? || prefer_variable)
    end

    # Check if a static font is requested
    def static_requested?
      variable == false
    end

    # Get axes as array (never nil)
    def axes
      Array(variable_axes)
    end

    # Check if transcoding might be needed (format specified but not available)
    def needs_transcode?(available_formats)
      return false unless format

      !available_formats.include?(format)
    end

    # Check if a subset of characters was requested
    def subset_requested?
      !(subset_unicodes.to_s.strip.empty? && subset_text.to_s.empty?)
    end

    # Check if a static instance of a variable font was requested
    def instance_requested?
      !instance.to_s.strip.empty?
    end

    # Axis coordinates of the requested instance: {"wght" => 300.0}
    def instance_coordinates
      FontOperations::Instance.parse(instance)
    end

    # Check if we need a specific collection index
    def specific_collection_index?
      !collection_index.nil?
    end
  end
end
