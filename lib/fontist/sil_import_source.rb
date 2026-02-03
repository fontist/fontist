require_relative "import_source"

module Fontist
  # Import source for SIL International fonts
  #
  # Tracks version and release information for fonts imported from SIL.
  class SilImportSource < ImportSource
    attribute :version, :string
    attribute :release_date, :string

    key_value do
      map "version", to: :version
      map "release_date", to: :release_date
    end

    # Returns the version as the differentiation key
    #
    # @return [String, nil] The version or nil
    def differentiation_key
      version
    end

    # Checks if this import source is older than the provided new source
    #
    # @param new_source [SilImportSource] The new source to compare against
    # @return [Boolean] true if this source is outdated
    def outdated?(new_source)
      return false unless new_source.is_a?(SilImportSource)
      return false unless version && new_source.version

      # Compare versions lexicographically (assumes semantic versioning)
      version < new_source.version
    rescue StandardError => e
      Fontist.ui.error("Error comparing SIL import sources: #{e.message}")
      false
    end

    # Returns a human-readable string representation
    #
    # @return [String] String representation for debugging/logging
    def to_s
      "SIL Fonts (version: #{version}, released: #{release_date})"
    end

    # Equality check based on differentiation key
    #
    # @param other [Object] The object to compare
    # @return [Boolean] true if objects are equal
    def ==(other)
      return false unless other.is_a?(SilImportSource)

      version == other.version
    end

    alias eql? ==
  end
end
