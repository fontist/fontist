module Fontist
  # JSON encoding and decoding through yeptris when available, with a
  # silent stdlib fallback. Both engines expose the same error classes.
  module JSON
    class Error < StandardError; end
    class ParseError < Error; end
    class DumpError < Error; end

    SCALAR_TYPES = [String, Symbol, Integer, TrueClass, FalseClass,
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
          value = normalize_value(object, {}.compare_by_identity)
          ::JSON.generate(value, max_nesting: false)
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

      # Match yeptris's accepted types and scalar conversions before stdlib
      # generation, including values nested inside containers.
      def normalize_value(value, ancestors)
        validate_class(value)
        case value
        when Hash, Array then normalize_container(value, ancestors)
        when Float then normalize_float(value)
        when *SCALAR_TYPES then value
        else
          raise DumpError, "cannot dump #{value.class}: unsupported object " \
                           "(JSON.generate calls to_json on custom types)"
        end
      end

      def validate_class(value)
        return unless value.class.name.nil?

        raise DumpError, "can't dump anonymous class #{value.class}"
      end

      def normalize_float(value)
        value.finite? ? value : value.to_s
      end

      def normalize_container(value, ancestors)
        raise DumpError, "circular reference" if ancestors.key?(value)

        ancestors[value] = true
        case value
        when Hash then normalize_hash(value, ancestors)
        else value.map { |item| normalize_value(item, ancestors) }
        end
      ensure
        ancestors.delete(value)
      end

      def normalize_hash(value, ancestors)
        if value.default_proc
          raise DumpError,
                "can't dump hash with default proc"
        end

        value.transform_values { |item| normalize_value(item, ancestors) }
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
