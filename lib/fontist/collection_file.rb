require "ttfunk"

module Fontist
  class CollectionFile
    include Enumerable

    class << self
      def from_path(path)
        io = ::File.new(path, "rb")

        yield new(build_collection(io))
      ensure
        io.close
      end

      private

      def build_collection(io)
        TTFunk::Collection.new(io)
      rescue StandardError => e
        raise Errors::FontFileError,
              "Font file could not be parsed: #{e.inspect}."
      end
    end

    def initialize(ttfunk_collection)
      @collection = ttfunk_collection
    end

    def count
      @collection.count
    end

    def each
      count.times do |index|
        yield self[index]
      end

      self
    end

    def [](index)
      FontFile.from_collection_index(@collection, index)
    end
  end
end
