require_relative "base_font_collection_index"

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
    class SystemIndex < BaseFontCollectionIndex
      private

      # Returns the path to the system index file
      #
      # @return [Pathname] Path to system_index.default_family.yml
      def index_path
        Fontist.system_index_path
      end

      # Returns all font file paths in system directories
      #
      # Uses SystemFont.load_system_font_paths which reads from system.yml
      # configuration to determine platform-specific system font paths
      #
      # @return [Array<String>] Array of font file paths
      def font_paths
        SystemFont.load_system_font_paths
      end
    end
  end
end