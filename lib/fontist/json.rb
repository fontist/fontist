module Fontist
  # JSON encoding and decoding through yeptris when available, with a
  # silent stdlib fallback. Both engines expose the same error classes.
  module JSON
    class Error < StandardError; end
    class ParseError < Error; end
    class DumpError < Error; end

    SCALAR_TYPES = [String, Integer, Float, TrueClass, FalseClass,
                    NilClass].freeze
    private_constant :SCALAR_TYPES

    class << self
      def parse(source)
        unless source.is_a?(String)
          raise ParseError,
                "cannot parse #{source.class}"
        end

        return Yeptris::JSON.load(source) if yeptris_available?

        ::JSON.parse(source, max_nesting: false)
      rescue *parse_errors => e
        raise ParseError, e.message
      end

      def dump(object)
        if yeptris_available?
          Yeptris::JSON.dump(object)
        else
          validate_value(object, {}.compare_by_identity)
          ::JSON.generate(object, max_nesting: false)
        end
      rescue *dump_errors => e
        raise DumpError, e.message
      end

      # Two-space-indented JSON for human-facing CLI output; yeptris's
      # generator is compact-only, so the indentation is applied here
      def pretty(object)
        pretty_value(object, 0)
      end

      private

      def yeptris_available?
        return @yeptris_available if defined?(@yeptris_available)

        @yeptris_available = begin
          require "yeptris"
          require "yeptris/json"
          true
        rescue LoadError
          require "json"
          false
        end
      end

      def parse_errors
        [TypeError, yeptris_available? ? Yeptris::Error : ::JSON::ParserError]
      end

      def dump_errors
        [TypeError, yeptris_available? ? Yeptris::Error : ::JSON::GeneratorError]
      end

      # Stdlib JSON stringifies arbitrary objects; keep yeptris's rejection
      # of non-JSON values, including those nested inside containers.
      def validate_value(value, ancestors)
        case value
        when Hash, Array then validate_container(value, ancestors)
        when *SCALAR_TYPES then nil
        else
          raise DumpError, "cannot dump #{value.class}"
        end
      end

      def validate_container(value, ancestors)
        raise DumpError, "circular reference" if ancestors.key?(value)

        ancestors[value] = true
        items = value.is_a?(Hash) ? value.values : value
        items.each { |item| validate_value(item, ancestors) }
      ensure
        ancestors.delete(value)
      end

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
