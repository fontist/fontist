require "find"
require_relative "extractors"

module Fontist
  module Import
    class RecursiveExtraction
      BOTH_FONTS_PATTERN = "**/*.{ttf,otf,ttc}".freeze
      ARCHIVE_EXTENSIONS = %w[zip msi exe cab].freeze

      def initialize(archive)
        @archive = archive
        @operations = []
      end

      def extension
        File.extname(filename(@archive)).sub(/^\./, "")
      end

      def extract(pattern)
        Array.new.tap do |results|
          Find.find(extracted_path) do |path| # rubocop:disable Style/CollectionMethods, Metrics/LineLength
            results << yield(path) if path.match(pattern)
          end
        end
      end

      def operations
        ensure_extracted
        @operations.size == 1 ? @operations.first : @operations
      end

      private

      def filename(file)
        if file.respond_to?(:original_filename)
          file.original_filename
        else
          File.basename(file)
        end
      end

      def ensure_extracted
        extracted_path
      end

      def extracted_path
        @extracted_path ||= extract_recursively(@archive)
      end

      def extract_recursively(archive)
        path = operate_on_archive(archive)
        return path if fonts_exist?(path)

        next_archive = find_archive(path)
        extract_recursively(next_archive)
      end

      def operate_on_archive(archive)
        extractor = choose_extractor(archive)
        save_operation(extractor)
        extractor.extract
      end

      # rubocop:disable Metrics/MethodLength
      def choose_extractor(archive)
        case filename(archive)
        when /\.msi$/i
          Extractors::OleExtractor.new(archive)
        when /\.cab$/i
          Extractors::CabExtractor.new(archive)
        when /\.exe$/i
          extractor = Extractors::SevenZipExtractor.new(archive)
          extractor.try ? extractor : Extractors::CabExtractor.new(archive)
        else
          Extractors::ZipExtractor.new(archive)
        end
      end
      # rubocop:enable Metrics/MethodLength

      def save_operation(extractor)
        @operations << { format: extractor.format }
      end

      def fonts_exist?(path)
        fonts = Dir.glob(File.join(path, BOTH_FONTS_PATTERN))
        !fonts.empty?
      end

      def find_archive(path)
        Dir.children(path)
          .map    { |file_name| File.join(path, file_name) }
          .max_by { |file_path| [file_type(file_path), File.size(file_path)] }
      end

      def file_type(file_path)
        extension = File.extname(file_path).delete(".")
        ARCHIVE_EXTENSIONS.include?(extension) ? 1 : 0
      end
    end
  end
end
