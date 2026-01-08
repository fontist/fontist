require "singleton"
require_relative "../system_index"

module Fontist
  module Indexes
    # Index for fonts in system font directories
    #
    # This index tracks all fonts in platform-specific system font
    # directories using a singleton pattern to ensure consistent state
    # across the application.
    #
    # ## Responsibilities
    #
    # - Maintain index of all system-installed fonts
    # - Provide fast font lookups by name and style
    # - Auto-rebuild when font directories change
    # - Cache results for performance
    #
    # ## Index File
    #
    # Located at: ~/.fontist/system_index.default_family.yml
    #
    # ## Platform-Specific Paths Indexed
    #
    # Scans all system font directories as defined in system.yml:
    #
    # - macOS: /System/Library/Fonts/, /Library/Fonts/, ~/Library/Fonts/
    # - Linux: /usr/share/fonts/, /usr/local/share/fonts/, ~/.fonts/
    # - Windows: %windir%/Fonts/, various system directories
    #
    # ## Usage
    #
    #   index = Fontist::Indexes::SystemIndex.instance
    #   fonts = index.find("Arial", "Bold")
    #   index.add_font("/Library/Fonts/Arial.ttf")
    #   index.rebuild(verbose: true)
    class SystemIndex
      include Singleton

      # Class method to reset the singleton instance cache
      #
      # @return [void]
      def self.reset_cache
        instance.reset_cache
      end

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: Fontist.system_index_path,
          paths_loader: -> { system_font_paths },
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
        @collection.to_file(Fontist.system_index_path)
      end

      # Rebuilds the entire index
      #
      # Scans all system font directories and updates the index file
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
          path: Fontist.system_index_path,
          paths_loader: -> { system_font_paths },
        )
      end

      private

      # Returns all font file paths in system directories
      #
      # Uses SystemFont.load_system_font_paths which reads from system.yml
      # configuration to determine platform-specific system font paths
      #
      # @return [Array<String>] Array of font file paths
      def system_font_paths
        SystemFont.load_system_font_paths
      end
    end
  end
end