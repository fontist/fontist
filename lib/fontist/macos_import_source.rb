require_relative "import_source"
require_relative "macos_framework_metadata"

module Fontist
  # Import source for macOS supplementary fonts
  #
  # Tracks the specific framework version, catalog posting date, and asset ID
  # for fonts imported from Apple's macOS font catalogs.
  class MacosImportSource < ImportSource
    attribute :framework_version, :integer
    attribute :posted_date, :string
    attribute :asset_id, :string

    key_value do
      map "framework_version", to: :framework_version
      map "posted_date", to: :posted_date
      map "asset_id", to: :asset_id
    end

    # Returns the asset ID in lowercase for consistent differentiation
    #
    # @return [String, nil] Lowercased asset ID or nil
    def differentiation_key
      asset_id&.downcase
    end

    # Checks if this import source is older than the provided new source
    #
    # @param new_source [MacosImportSource] The new source to compare against
    # @return [Boolean] true if this source is outdated
    def outdated?(new_source)
      return false unless new_source.is_a?(MacosImportSource)
      return false unless posted_date && new_source.posted_date

      Time.parse(posted_date) < Time.parse(new_source.posted_date)
    rescue StandardError => e
      Fontist.ui.error("Error comparing import sources: #{e.message}")
      false
    end

    # Gets the minimum macOS version for this framework
    #
    # @return [String, nil] The minimum macOS version or nil
    def min_macos_version
      MacosFrameworkMetadata.min_macos_version(framework_version)
    end

    # Gets the maximum macOS version for this framework
    #
    # @return [String, nil] The maximum macOS version or nil if unlimited
    def max_macos_version
      MacosFrameworkMetadata.max_macos_version(framework_version)
    end

    # Checks if this import source is compatible with a specific macOS version
    #
    # @param macos_version [String] The macOS version to check
    # @return [Boolean] true if compatible
    def compatible_with_macos?(macos_version)
      MacosFrameworkMetadata.compatible_with_macos?(framework_version, macos_version)
    end

    # Returns a human-readable string representation
    #
    # @return [String] String representation for debugging/logging
    def to_s
      "macOS Font#{framework_version} (posted: #{posted_date}, asset: #{asset_id})"
    end

    # Gets the parser class name for this framework
    #
    # @return [String] The fully qualified parser class name
    def parser_class
      MacosFrameworkMetadata.parser_class(framework_version)
    end

    # Gets the description for this framework
    #
    # @return [String] The framework description
    def description
      MacosFrameworkMetadata.description(framework_version)
    end

    # Equality check based on differentiation key
    #
    # @param other [Object] The object to compare
    # @return [Boolean] true if objects are equal
    def ==(other)
      return false unless other.is_a?(MacosImportSource)

      framework_version == other.framework_version &&
        asset_id&.downcase == other.asset_id&.downcase
    end

    alias eql? ==
  end
end