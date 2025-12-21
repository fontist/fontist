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
      # Keep tempfiles alive during font extraction to prevent Windows GC issues
      # On Windows, GC finalizers trying to delete files can fail with EACCES
      # if files are still being accessed. By keeping references, we let Ruby's
      # normal GC handle cleanup when the CollectionFile is no longer referenced.
      @tempfiles = []
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
      tmpfile = Tempfile.new(["font", ".ttf"])
      tmpfile.binmode

      File.open(@path, "rb") do |io|
        # Get font from collection
        font = @collection.font(index, io)

        # Write to tempfile
        font.to_file(tmpfile.path)
      end

      tmpfile.close
      
      # Keep tempfile alive to prevent GC issues on Windows
      @tempfiles << tmpfile
      
      # Load and extract metadata using FontFile
      # Tempfile will be deleted when CollectionFile is GC'd
      FontFile.from_path(tmpfile.path)
    end

    # Removed extract_font_info method - now using FontFile.from_path
  end
end
