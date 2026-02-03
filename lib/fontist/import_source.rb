require "lutaml/model"

module Fontist
  # Base class for import source metadata
  #
  # This provides a polymorphic way to track where and how fonts were imported from.
  # Each subclass handles source-specific metadata while maintaining a consistent interface.
  #
  # @abstract Base class for import sources. Use subclasses like MacosImportSource,
  #          GoogleImportSource, or SilImportSource instead.
  class ImportSource < Lutaml::Model::Serializable
    attribute :type, :string, polymorphic_class: true

    key_value do
      map "type", to: :type, polymorphic_map: {
        "macos" => "Fontist::MacosImportSource",
        "google" => "Fontist::GoogleImportSource",
        "sil" => "Fontist::SilImportSource",
      }
    end

    # Returns a key that can be used to differentiate this source from others
    # @abstract Subclasses must implement this
    # @return [String] A unique key for this import source
    def differentiation_key
      raise NotImplementedError,
            "#{self.class} must implement #differentiation_key"
    end

    # Checks if this source is older than the provided new source
    # @abstract Subclasses must implement this
    # @param new_source [ImportSource] The new source to compare against
    # @return [Boolean] true if this source is outdated
    def outdated?(new_source)
      raise NotImplementedError, "#{self.class} must implement #outdated?"
    end

    # String representation of the import source
    # @abstract Subclasses should implement this for debugging/logging
    # @return [String] Human-readable string representation
    def to_s
      "#{self.class.name} (type: #{type})"
    end
  end
end
