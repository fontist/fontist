require "fontisan"
require "tempfile"

module Fontist
  class CollectionFile
    include Enumerable

    class << self
      def from_path(path)
        collection = build_collection(path)

        yield new(collection, path)
      end

      private

      def build_collection(path)
        Fontisan::TrueTypeCollection.from_file(path)
      rescue StandardError => e
        raise Errors::FontFileError,
              "Font file could not be parsed: #{e.inspect}."
      end
    end

    def initialize(fontisan_collection, path)
      @collection = fontisan_collection
      @path = path
    end

    def count
      @collection.num_fonts
    end

    def each
      count.times do |index|
        yield self[index]
      end

      self
    end

    def [](index)
      # Extract font from collection to temporary file,
      # then load and extract metadata
      Tempfile.create(["font", ".ttf"]) do |tmpfile|
        result = nil
        File.open(@path, "rb") do |io|
          # Get font from collection
          font = @collection.font(index, io)

          # Write to tempfile
          font.to_file(tmpfile.path)

          # Load and extract metadata using FontFile
          result = FontFile.from_path(tmpfile.path)
        end

        # On Windows, explicitly close tempfile to release file handle
        # This allows Ruby's automatic cleanup to delete the file properly
        tmpfile.close if Fontist::Utils::System.user_os == :windows

        result
      end
    end

    # Removed extract_font_info method - now using FontFile.from_path
  end
end
