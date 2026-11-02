require "fileutils"

module Fontist
  module FontOperations
    # Bundles several font files into one TTC/OTC (or dfont) collection.
    module Pack
      FORMATS = %w[ttc otc dfont].freeze

      module_function

      # @param output [String] collection path; extension picks the format
      #   unless +format+ is given
      # @param files [Array<String>] two or more font files
      # @return [String] the written collection path
      def call(output, files, format: nil)
        FontOperations.guard("Packing collection") do
          format = (format || File.extname(output).delete(".")).to_s.downcase
          validate!(files, format)
          write(output, files, format)
        end
      end

      def validate!(files, format)
        unless FORMATS.include?(format)
          raise Error, "Unsupported collection format '#{format}'. " \
                       "Use one of: #{FORMATS.join(', ')}"
        end
        if files.size < 2
          raise Error, "A collection needs at least two font files"
        end

        missing = files.reject { |f| File.exist?(f) }
        raise Errors::SourceNotFoundError, missing.first if missing.any?
      end

      def write(output, files, format)
        FileUtils.mkdir_p(File.dirname(output))
        Fontisan::Commands::PackCommand.new(
          files, output: output, format: format
        ).run
        unless File.size?(output)
          raise Error, "No collection was written to #{output}"
        end

        output
      end
    end
  end
end
