require "fileutils"

module Fontist
  module FontOperations
    # Extracts one member of a TTC/OTC collection as a standalone font.
    module Extract
      module_function

      # @param collection_path [String] TTC/OTC file
      # @param index [Integer] zero-based member index
      # @param output_dir [String] directory to write into
      # @return [String] path of the standalone font
      def call(collection_path, index:, output_dir:)
        FontOperations.guard("Extracting member #{index}") do
          check_index!(collection_path, index)
          unpack(collection_path, index, output_dir)
        end
      end

      def unpack(collection_path, index, output_dir)
        Fontisan::Commands::UnpackCommand.new(
          collection_path, output_dir: output_dir, font_index: index
        ).run[:extracted_files].first
      end

      def check_index!(path, index)
        raise Errors::SourceNotFoundError, path unless File.exist?(path)

        count = member_count(path)
        return if index.is_a?(Integer) && index >= 0 && index < count

        raise Errors::CollectionIndexError.new(index, count - 1)
      end

      def collection?(path)
        File.open(path, "rb") { |io| io.read(4) } == "ttcf"
      rescue SystemCallError
        false
      end

      def member_count(path)
        unless collection?(path)
          raise Error, "#{path} is not a TTC/OTC collection"
        end

        File.open(path, "rb") do |io|
          io.seek(8)
          io.read(4).unpack1("N")
        end
      end
    end
  end
end
