require_relative "base_font_collection_index"

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
    class UserIndex < BaseFontCollectionIndex
      private

      # Returns the path to the user index file
      #
      # @return [Pathname] Path to user_index.default_family.yml
      def index_path
        Fontist.user_index_path
      end

      # Returns all font file paths in the user location
      #
      # Uses UserLocation to determine the correct base path,
      # which varies by platform and user configuration
      #
      # @return [Array<String>] Array of font file paths
      def font_paths
        # Create a temporary UserLocation to get the base path
        # We pass nil for formula since we're just getting the directory
        location = Fontist::InstallLocations::UserLocation.new(nil)
        base = location.base_path

        # Scan for all font files under the user location
        # Uses case-insensitive glob patterns that work on all platforms,
        # including Linux where File::FNM_CASEFOLD is ignored
        patterns = Fontist::Utils.font_file_patterns(base.join("**").to_s)
        patterns.flat_map { |pattern| Dir.glob(pattern) }
      rescue StandardError => e
        # If we can't determine user path, return empty array
        Fontist.ui.debug("Error scanning user font paths: #{e.message}")
        []
      end
    end
  end
end