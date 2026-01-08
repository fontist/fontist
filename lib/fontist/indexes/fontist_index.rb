require "singleton"
require_relative "../system_index"

module Fontist
  module Indexes
    # Index for fonts installed in the fontist library
    #
    # This index tracks all fonts installed in ~/.fontist/fonts/{formula-key}/
    # using a singleton pattern to ensure consistent state across the application.
    #
    # ## Responsibilities
    #
    # - Maintain index of all fontist-managed fonts
    # - Provide fast font lookups by name and style
    # - Auto-rebuild when font directories change
    # - Cache results for performance
    #
    # ## Index File
    #
    # Located at: ~/.fontist/fontist_index.default_family.yml
    #
    # ## Usage
    #
    #   index = Fontist::Indexes::FontistIndex.instance
    #   fonts = index.find("Roboto", "Regular")
    #   index.add_font("/path/to/font.ttf")
    #   index.rebuild(verbose: true)
    class FontistIndex
      include Singleton

      # Class method to reset the singleton instance cache
      #
      # @return [void]
      def self.reset_cache
        instance.reset_cache
      end

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: Fontist.fontist_index_path,
          paths_loader: -> { fontist_font_paths },
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
        @collection.to_file(Fontist.fontist_index_path)
      end

      # Rebuilds the entire index
      #
      # Scans all fontist font directories and updates the index file
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
          path: Fontist.fontist_index_path,
          paths_loader: -> { fontist_font_paths },
        )
      end

      private

      # Returns all font file paths in the fontist library
      #
      # @return [Array<String>] Array of font file paths
      def fontist_font_paths
        Dir.glob(Fontist.fonts_path.join("**", "*.{ttf,otf,ttc,otc}"))
      end
    end
  end
end