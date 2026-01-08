require "singleton"
require_relative "../system_index"

module Fontist
  module Indexes
    # Index for fonts installed in the user font directory
    #
    # This index tracks all fonts installed in the user-specific font location
    # (platform-dependent, typically with /fontist subdirectory) using a
    # singleton pattern to ensure consistent state across the application.
    #
    # ## Responsibilities
    #
    # - Maintain index of all user location fonts
    # - Provide fast font lookups by name and style
    # - Auto-rebuild when font directories change
    # - Cache results for performance
    #
    # ## Index File
    #
    # Located at: ~/.fontist/user_index.default_family.yml
    #
    # ## Platform-Specific Paths Indexed
    #
    # - macOS: ~/Library/Fonts/fontist/**/*.{ttf,otf,ttc,otc}
    # - Linux: ~/.local/share/fonts/fontist/**/*.{ttf,otf,ttc,otc}
    # - Windows: %LOCALAPPDATA%/Microsoft/Windows/Fonts/fontist/**/*.{ttf,otf,ttc,otc}
    #
    # ## Usage
    #
    #   index = Fontist::Indexes::UserIndex.instance
    #   fonts = index.find("Arial", "Bold")
    #   index.add_font("/path/to/font.ttf")
    #   index.rebuild(verbose: true)
    class UserIndex
      include Singleton

      # Class method to reset the singleton instance cache
      #
      # @return [void]
      def self.reset_cache
        instance.reset_cache
      end

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: Fontist.user_index_path,
          paths_loader: -> { user_font_paths },
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
        @collection.to_file(Fontist.user_index_path)
      end

      # Rebuilds the entire index
      #
      # Scans all user font directories and updates the index file
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
          path: Fontist.user_index_path,
          paths_loader: -> { user_font_paths },
        )
      end

      private

      # Returns all font file paths in the user location
      #
      # Uses UserLocation to determine the correct base path,
      # which varies by platform and user configuration
      #
      # @return [Array<String>] Array of font file paths
      def user_font_paths
        # Create a temporary UserLocation to get the base path
        # We pass nil for formula since we're just getting the directory
        location = Fontist::InstallLocations::UserLocation.new(nil)
        base = location.base_path

        # Scan for all font files under the user location
        # Uses lowercase extensions since font files are normalized to
        # lowercase extensions during installation for cross-platform consistency
        Dir.glob(base.join("**", "*.{ttf,otf,ttc,otc}"))
      rescue StandardError => e
        # If we can't determine user path, return empty array
        Fontist.ui.debug("Error scanning user font paths: #{e.message}")
        []
      end
    end
  end
end