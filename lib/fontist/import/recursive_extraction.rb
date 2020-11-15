require "find"
require_relative "extractors"
require_relative "files/font_detector"

module Fontist
  module Import
    class RecursiveExtraction
      BOTH_FONTS_PATTERN = "**/*.{ttf,otf,ttc}".freeze
      ARCHIVE_EXTENSIONS = %w[zip msi exe cab].freeze
      LICENSE_PATTERN = /(OFL\.txt|UFL\.txt|LICENSE\.txt|COPYING)$/i.freeze

      def initialize(archive, subarchive: nil)
        @archive = archive
        @subarchive = subarchive
        @operations = []
      end

      def extension
        File.extname(filename(@archive)).sub(/^\./, "")
      end

      def font_files
        select { |path| font_file?(path) }
          .map { |path| Otf::FontFile.new(path) }
      end

      def font_collection_files
        select { |path| collection_file?(path) }
          .map { |path| Files::CollectionFile.new(path) }
      end

      def license_text
        select { |path| license?(path) }
          .map { |path| File.read(path) }
          .first
      end

      def operations
        ensure_extracted
        @operations.size == 1 ? @operations.first : @operations
      end

      private

      def select
        Array.new.tap do |results|
          Find.find(extracted_path) do |path| # rubocop:disable Style/CollectionMethods, Metrics/LineLength
            results << path if yield(path)
          end
        end
      end

      def font_file?(file)
        Files::FontDetector.font?(file)
      end

      def collection_file?(file)
        Files::FontDetector.collection?(file)
      end

      def license?(file)
        file.match?(LICENSE_PATTERN)
      end

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
        Fontist.ui.say("Extracting #{archive} with #{extractor.class.name}")

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
        matched_by_extension(path) || matched_by_detector(path)
      end

      def matched_by_extension(path)
        fonts = Dir.glob(File.join(path, BOTH_FONTS_PATTERN))
        !fonts.empty?
      end

      def matched_by_detector(path)
        Find.find(path) do |entry_path| # rubocop:disable Style/CollectionMethods, Metrics/LineLength
          return true if Files::FontDetector.font_or_collection?(entry_path)
        end
      end

      def find_archive(path)
        paths = Dir.children(path).map { |file| File.join(path, file) }
        by_subarchive(paths) || by_size(paths)
      end

      def by_subarchive(paths)
        return unless @subarchive

        path_found = paths.detect do |path|
          @subarchive == File.basename(path)
        end

        return unless path_found

        save_operation_subarchive(path_found)

        path_found
      end

      def save_operation_subarchive(path)
        @operations.last[:options] ||= {}
        @operations.last[:options][:subarchive] = File.basename(path)
      end

      def by_size(paths)
        paths.max_by do |path|
          [file_type(path), File.size(path)]
        end
      end

      def file_type(file_path)
        extension = File.extname(file_path).delete(".")
        ARCHIVE_EXTENSIONS.include?(extension) ? 1 : 0
      end
    end
  end
end
