require "fileutils"

module Fontist
  module FontOperations
    # Converts a font file to another format via Fontisan.
    module Convert
      TARGETS = %w[ttf otf woff woff2].freeze
      MAGIC = {
        "ttf" => ["\x00\x01\x00\x00".b, "true".b],
        "otf" => ["OTTO".b],
        "woff" => ["wOFF".b],
        "woff2" => ["wOF2".b],
      }.freeze

      module_function

      # @param source [String] font file
      # @param target_format [String] one of TARGETS
      # @param output [String] where to write the converted font
      # @return [String] output path (verified to carry the target's magic)
      def call(source, target_format, output)
        target = target_format.to_s.downcase
        FontOperations.guard("Converting to #{target}") do
          check!(source, target)
          run(source, target, output)
          verify!(output, target)
          output
        end
      end

      def check!(source, target)
        unless TARGETS.include?(target)
          raise Errors::UnsupportedTranscodeError.new(
            File.extname(source).delete("."), target
          )
        end
        raise Errors::SourceNotFoundError, source unless File.exist?(source)
      end

      def run(source, target, output)
        FileUtils.mkdir_p(File.dirname(output))
        Fontisan::Reference.convert(source, to: target, output: output)
      end

      def verify!(path, target)
        head = File.file?(path) ? File.binread(path, 4) : nil
        return if MAGIC.fetch(target).include?(head)

        raise Error, "Fontisan did not produce a #{target} file at #{path}"
      end
    end
  end
end
