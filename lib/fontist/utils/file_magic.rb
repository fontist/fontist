module Fontist
  module Utils
    class FileMagic
      MAP_MAGIC_TO_TYPE = {
        "\x00\x01\x00\x00\x00" => :ttf,
        "\x4f\x54\x54\x4f" => :otf,
        "\x74\x74\x63\x66" => :ttc,
      }.freeze

      def self.detect(path)
        new(path).detect
      end

      def self.max_magic
        @max_magic ||= MAP_MAGIC_TO_TYPE.keys.map(&:bytesize).max
      end

      def initialize(path)
        @path = path
      end

      def detect
        beginning = File.binread(@path, self.class.max_magic)

        MAP_MAGIC_TO_TYPE.each do |magic, type|
          slice = beginning.byteslice(0, magic.bytesize)

          return type if slice == magic
        end

        nil
      end
    end
  end
end
