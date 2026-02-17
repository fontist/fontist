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

    # Format preferences
    attribute :prefer_format, :string

    # Transcoding options (used when format not available)
    attribute :transcode_path, :string
    attribute :keep_original, :boolean, default: true

    # Collection handling
    attribute :collection_index, :integer

    # Convenience constructor for CLI
    def self.from_options(options = {})
      new(
        format: options[:format],
        variable_axes: parse_variable_axes(options[:variable_axes]),
        prefer_variable: options[:prefer_variable] || false,
        prefer_format: options[:prefer_format],
        transcode_path: options[:transcode_path],
        keep_original: options.fetch(:keep_original, true),
        collection_index: options[:collection_index],
      )
    end

    def self.parse_variable_axes(value)
      return nil if value.nil?
      return value if value.is_a?(Array)

      value.to_s.split(",").map(&:strip).compact
    end

    # Check if any format constraints are specified
    def has_constraints?
      !!(format || variable_axes&.any? || prefer_variable || prefer_format)
    end

    # Check if variable font is requested
    def variable_requested?
      !!(variable_axes&.any? || prefer_variable)
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

    # Check if we need a specific collection index
    def specific_collection_index?
      !collection_index.nil?
    end
  end
end
