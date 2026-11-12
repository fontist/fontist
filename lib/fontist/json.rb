module Fontist
  # JSON encoding and decoding through yeptris when available, with a
  # silent stdlib fallback. Both engines expose the same error classes.
  module JSON
    class Error < StandardError; end
    class ParseError < Error; end
    class DumpError < Error; end

    SCALAR_TYPES = [Integer, TrueClass, FalseClass,
                    NilClass].freeze
    private_constant :SCALAR_TYPES

    class << self
      def parse(source)
        unless source.is_a?(String)
          raise ParseError,
                "cannot parse #{source.class}"
        end

        return Yeptris::JSON.load(source) if yeptris_available?

        value = ::JSON.parse(source, max_nesting: 1000)
        validate_nesting(value)
        value
      rescue *parse_errors => e
        raise ParseError, e.message
      end

      def dump(object)
        if yeptris_available?
          Yeptris::JSON.dump(object)
        else
          value = normalize_value(object, {}.compare_by_identity)
          ::JSON.generate(value, max_nesting: false)
            .encode(Encoding::ISO_8859_1).force_encoding(Encoding::UTF_8)
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
          require "time"
          false
        end
      end

      def parse_errors
        [TypeError, yeptris_available? ? Yeptris::Error : ::JSON::ParserError]
      end

      def dump_errors
        [TypeError, yeptris_available? ? Yeptris::Error : ::JSON::GeneratorError]
      end

      # Yeptris counts scalar values towards its 1000-level limit, but permits
      # an empty container at the last level. Stdlib's container limit alone
      # does not enforce this boundary consistently across json versions.
      def validate_nesting(value)
        pending = [[value, 0]]
        until pending.empty?
          item, depth = pending.pop
          raise ParseError, "JSON nesting exceeds 1000 levels" if depth >= 1000

          children = item.is_a?(Hash) ? item.values : item
          next unless children.is_a?(Array)

          children.each { |child| pending << [child, depth + 1] }
        end
      end

      # Match yeptris's accepted types and scalar conversions before stdlib
      # generation, including values nested inside containers.
      def normalize_value(value, ancestors)
        validate_class(value)
        case value
        when Hash, Array then normalize_container(value, ancestors)
        when *SCALAR_TYPES then value
        else normalize_scalar(value)
        end
      end

      def validate_class(value)
        return unless value.class.name.nil?

        raise DumpError, "can't dump anonymous class #{value.class}"
      end

      def normalize_scalar(value)
        case value
        when Float then value.finite? ? value : value.to_s
        when String, Symbol then normalize_string(value.to_s)
        when Time, Date then normalize_string(value.iso8601)
        else
          raise DumpError, "cannot dump #{value.class}: unsupported object " \
                           "(JSON.generate calls to_json on custom types)"
        end
      end

      # Yeptris preserves string bytes even when they are not valid UTF-8.
      # Map bytes through Latin-1 so stdlib can escape JSON syntax normally;
      # dump reverses the mapping after generation without changing the bytes.
      def normalize_string(value)
        value.encode(Encoding::UTF_8, Encoding::ISO_8859_1)
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

        value.each_with_object({}.compare_by_identity) do |(key, item), result|
          result[normalize_string(key.to_s)] = normalize_value(item, ancestors)
        end
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
