require "fileutils"

module Fontist
  module FontOperations
    # Keeps only the glyphs for the given characters.
    module Subset
      NO_GLYPHS = "None of the requested characters exist in".freeze
      UNICODE_PART = /\A(u\+)?\h+(-(u\+)?\h+)?\z/i

      module_function

      # @param source [String] font file
      # @param output [String] where to write the subset font
      # @param unicodes [String, Array<Integer>, nil] "U+0020-007E,U+00E9"
      #   or codepoints
      # @param text [String, nil] characters to keep
      # @return [String] output path
      def call(source, output, unicodes: nil, text: nil)
        FontOperations.guard("Subsetting") do
          raise Errors::SourceNotFoundError, source unless File.exist?(source)

          codepoints = parse_unicodes(unicodes) + text.to_s.codepoints
          if codepoints.empty?
            raise Error, "No characters to keep: give unicodes or text"
          end

          write(source, output, codepoints)
        end
      end

      def write(source, output, codepoints)
        binary = Fontisan::Reference.subset(
          source, unicodes: codepoints, profile: "web"
        )
        FileUtils.mkdir_p(File.dirname(output))
        File.binwrite(output, binary)
        output
      rescue Fontisan::Error => e
        raise unless e.message.start_with?(NO_GLYPHS)

        raise Error, e.message
      end

      # "U+0020-007E,U+00E9" => [32..126, 233].flatten
      def parse_unicodes(value)
        return Array(value).map(&:to_i) unless value.nil? || value.is_a?(String)

        value.to_s.split(/[,\s]+/).reject(&:empty?).flat_map do |part|
          parse_part(part)
        end
      end

      def parse_part(part)
        unless part.match?(UNICODE_PART)
          raise Error, "Invalid unicode '#{part}'. Use e.g. U+0020-007E,U+00E9"
        end

        first, last = part.split("-", 2)
          .map { |h| h.sub(/\Au\+/i, "").to_i(16) }
        last ? (first..last).to_a : [first]
      end
    end
  end
end
