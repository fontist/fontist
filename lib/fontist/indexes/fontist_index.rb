require_relative "base_font_collection_index"

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
    class FontistIndex < BaseFontCollectionIndex
      private

      # Returns the path to the fontist index file
      #
      # @return [Pathname] Path to fontist_index.default_family.yml
      def index_path
        Fontist.fontist_index_path
      end

      # Returns all font file paths in the fontist library
      #
      # Uses case-insensitive glob patterns that work on all platforms,
      # including Linux where File::FNM_CASEFOLD is ignored
      #
      # @return [Array<String>] Array of font file paths
      def font_paths
        patterns = Fontist::Utils.font_file_patterns(Fontist.fonts_path.join("**").to_s)
        patterns.flat_map { |pattern| Dir.glob(pattern) }
      end
    end
  end
end