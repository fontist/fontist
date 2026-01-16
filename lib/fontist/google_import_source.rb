require_relative "import_source"

module Fontist
  # Import source for Google Fonts
  #
  # Tracks the specific commit, API version, and family information
  # for fonts imported from Google Fonts.
  #
  # Note: Google Fonts filenames are NOT versioned because Google Fonts
  # is a live service that always provides the latest version. The commit_id
  # is tracked in import_source for metadata and update detection only.
  class GoogleImportSource < ImportSource
    attribute :commit_id, :string
    attribute :api_version, :string
    attribute :last_modified, :string
    attribute :family_id, :string

    key_value do
      map "commit_id", to: :commit_id
      map "api_version", to: :api_version
      map "last_modified", to: :last_modified
      map "family_id", to: :family_id
    end

    # Returns nil - Google Fonts formulas use simple filenames
    #
    # Google Fonts is a live service, so formulas always point to the
    # latest version. The commit_id is stored for metadata only.
    #
    # @return [nil] No differentiation needed for Google Fonts
    def differentiation_key
      nil
    end

    # Checks if this import source is older than the provided new source
    #
    # @param new_source [GoogleImportSource] The new source to compare against
    # @return [Boolean] true if this source is outdated
    def outdated?(new_source)
      return false unless new_source.is_a?(GoogleImportSource)
      return false unless commit_id && new_source.commit_id

      # Compare commit IDs - different commits mean potential update
      commit_id != new_source.commit_id
    rescue StandardError => e
      Fontist.ui.error("Error comparing Google import sources: #{e.message}")
      false
    end

    # Returns a human-readable string representation
    #
    # @return [String] String representation for debugging/logging
    def to_s
      "Google Fonts (commit: #{commit_id&.slice(0,
                                                7)}, family: #{family_id}, API: #{api_version})"
    end

    # Equality check based on commit ID
    #
    # @param other [Object] The object to compare
    # @return [Boolean] true if objects are equal
    def ==(other)
      return false unless other.is_a?(GoogleImportSource)

      commit_id == other.commit_id
    end

    alias eql? ==
  end
end
