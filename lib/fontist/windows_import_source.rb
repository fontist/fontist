require_relative "import_source"

module Fontist
  # Import source for Windows Features on Demand (FOD) supplementary fonts
  #
  # Tracks the capability name and minimum Windows version for fonts
  # installed via Add-WindowsCapability.
  class WindowsImportSource < ImportSource
    attribute :capability_name, :string   # e.g. "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0"
    attribute :min_windows_version, :string  # e.g. "10.0"

    key_value do
      map "capability_name", to: :capability_name
      map "min_windows_version", to: :min_windows_version
    end

    # Returns the capability name for differentiation
    #
    # @return [String, nil] Capability name or nil
    def differentiation_key
      capability_name
    end

    # Checks if this import source is older than the provided new source
    #
    # @param new_source [WindowsImportSource] The new source to compare against
    # @return [Boolean] true if this source is outdated
    def outdated?(new_source)
      return false unless new_source.is_a?(WindowsImportSource)

      # Windows FOD capabilities don't have versioned updates in the same way;
      # they are either present or not. Always return false.
      false
    end

    # Returns a human-readable string representation
    #
    # @return [String] String representation for debugging/logging
    def to_s
      "Windows FOD (capability: #{capability_name}, min_version: #{min_windows_version})"
    end

    # Equality check based on capability name
    #
    # @param other [Object] The object to compare
    # @return [Boolean] true if objects are equal
    def ==(other)
      return false unless other.is_a?(WindowsImportSource)

      capability_name == other.capability_name
    end

    alias eql? ==
  end
end
