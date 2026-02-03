require "digest"

module Fontist
  module PathScanning
    FONT_EXTENSIONS = [
      ".ttf", ".TTF", ".ttc", ".TTC",
      ".otf", ".OTF",
      ".woff", ".woff2", ".WOFF", ".WOFF2"
    ].freeze

    class << self
      # More efficient than glob for just listing fonts in a directory
      # Returns: Array of full paths to font files
      def list_font_directory(directory)
        return [] unless Dir.exist?(directory)

        # Use Dir.children (faster than glob for just listing)
        Dir.children(directory).select do |filename|
          FONT_EXTENSIONS.any? { |ext| filename.end_with?(ext) }
        end.map { |filename| File.join(directory, filename) }
      rescue Errno::EACCES, Errno::EPERM
        # Handle permission errors gracefully
        []
      end

      # Glob-based font file scanning with filtering
      # Use this for recursive patterns or multiple directories
      def glob_font_files(pattern)
        Dir.glob(pattern).select { |f| font_file?(f) }.uniq
      end

      private

      def font_file?(path)
        return false unless File.file?(path)

        filename = File.basename(path)
        FONT_EXTENSIONS.any? { |ext| filename.end_with?(ext) }
      end
    end
  end
end
