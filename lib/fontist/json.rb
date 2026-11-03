require "yeptris"
require "yeptris/json"

module Fontist
  # JSON encoding and decoding through yeptris's native engine, replacing
  # the json gem as fontist's JSON backend. The yeptris parser and
  # generator produce and accept the same plain Ruby structures as the
  # json gem (string keys, arrays, scalars), so this module is a
  # drop-in surface; call sites rescue the module's error classes
  # instead of JSON::ParserError and JSON::GeneratorError.
  module JSON
    class Error < StandardError; end
    class ParseError < Error; end
    class DumpError < Error; end

    class << self
      def parse(source)
        unless source.is_a?(String)
          raise ParseError,
                "cannot parse #{source.class}"
        end

        Yeptris::JSON.load(source)
      rescue Yeptris::Error, TypeError => e
        raise ParseError, e.message
      end

      def dump(object)
        Yeptris::JSON.dump(object)
      rescue Yeptris::Error, TypeError => e
        raise DumpError, e.message
      end

      # Two-space-indented JSON for human-facing CLI output; yeptris's
      # generator is compact-only, so the indentation is applied here
      def pretty(object)
        pretty_value(object, 0)
      end

      private

      def pretty_value(value, depth)
        case value
        when Hash then pretty_object(value, depth)
        when Array then pretty_array(value, depth)
        else dump(value)
        end
      end

      def pretty_object(hash, depth)
        return "{}" if hash.empty?

        inner = hash.map do |key, value|
          "#{indent(depth + 1)}#{dump(key.to_s)}: #{pretty_value(value,
                                                                 depth + 1)}"
        end

        "{\n#{inner.join(",\n")}\n#{indent(depth)}}"
      end

      def pretty_array(array, depth)
        return "[]" if array.empty?

        inner = array.map do |value|
          "#{indent(depth + 1)}#{pretty_value(value, depth + 1)}"
        end

        "[\n#{inner.join(",\n")}\n#{indent(depth)}]"
      end

      def indent(depth)
        "  " * depth
      end
    end
  end
end
