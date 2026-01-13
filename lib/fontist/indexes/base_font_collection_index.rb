require "singleton"
require_relative "../system_index"

module Fontist
  module Indexes
    # Base class for font collection indexes
    #
    # Provides common functionality for managing font indexes using
    # SystemIndexFontCollection with different path loaders.
    #
    # Subclasses must implement:
    # - index_path: Returns the path where the index file should be stored
    # - font_paths: Returns an array of font file paths to index
    #
    # ## Singleton Pattern
    #
    # All index classes use Singleton to ensure consistent state across
    # the application and enable caching.
    class BaseFontCollectionIndex
      include Singleton

      # Class method to reset the singleton instance cache
      #
      # @return [void]
      def self.reset_cache
        instance.reset_cache
      end

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: index_path,
          paths_loader: -> { font_paths },
        )
      end

      # Finds fonts by name and optional style
      #
      # @param font_name [String] Font family name
      # @param style [String, nil] Optional style (e.g., "Regular", "Bold")
      # @return [Array<SystemIndexFont>, nil] Found fonts or nil
      def find(font_name, style = nil)
        @collection.find(font_name, style)
      end

      # Enable read-only mode for operations that don't need index rebuilding
      # This is used during manifest compilation to avoid expensive index checks
      #
      # @return [self] Returns self for chaining
      def read_only_mode
        @collection.read_only_mode
        self
      end

      # Returns all fonts in the index
      #
      # @return [Array<SystemIndexFont>] All indexed fonts
      def fonts
        @collection.fonts
      end

      # Checks if a font exists at the given path
      #
      # @param path [String] Full path to font file
      # @return [Boolean] true if font exists in index
      def font_exists?(path)
        @collection.fonts.any? { |f| f.path == path }
      end

      # Adds a font to the index
      #
      # Triggers index rebuild to ensure font is included
      #
      # @param path [String] Full path to installed font file
      # @return [void]
      def add_font(path)
        # Reset verification flag to force re-check
        @collection.reset_verification!

        # Force rebuild to include new font
        @collection.build(forced: true, verbose: false)
      end

      # Removes a font from the index
      #
      # Updates index file immediately
      #
      # @param path [String] Full path to font file to remove
      # @return [void]
      def remove_font(path)
        @collection.fonts.delete_if { |f| f.path == path }
        @collection.to_file(index_path)
      end

      # Rebuilds the entire index
      #
      # Scans all font directories and updates the index file
      #
      # @param verbose [Boolean] Show detailed progress information
      # @return [void]
      def rebuild(verbose: false)
        @collection.rebuild(verbose: verbose)
      end

      # Resets the singleton instance
      #
      # Forces a new instance to be created on next access
      # Used primarily for testing to ensure clean state
      #
      # @return [void]
      def reset_cache
        @collection = SystemIndexFontCollection.from_file(
          path: index_path,
          paths_loader: -> { font_paths },
        )
      end

      private

      # Returns the path to the index file
      #
      # Must be implemented by subclasses
      #
      # @return [String, Pathname] Path to index file
      def index_path
        raise NotImplementedError, "#{self.class} must implement #index_path"
      end

      # Returns all font file paths to be indexed
      #
      # Must be implemented by subclasses
      #
      # @return [Array<String>] Array of font file paths
      def font_paths
        raise NotImplementedError, "#{self.class} must implement #font_paths"
      end
    end
  end
end
