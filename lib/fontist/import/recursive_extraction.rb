require "find"
require_relative "extractors"
require_relative "files/font_detector"

module Fontist
  module Import
    class RecursiveExtraction
      FONTS_PATTERN = "**/*.{ttf,otf,ttc}".freeze
      ARCHIVE_EXTENSIONS = %w[zip msi exe cab].freeze
      LICENSE_PATTERN = /(ofl\.txt|ufl\.txt|licenses?\.txt|copying)$/i.freeze

      def initialize(archive, subarchive: nil, subdir: nil)
        @archive = archive
        @subarchive = subarchive
        @subdir = subdir
        @operations = []
        @font_files = []
        @collection_files = []
      end

      def extension
        fetch_extension(@archive)
      end

      def font_files
        ensure_extracted
        @font_files
      end

      def font_collection_files
        ensure_extracted
        @collection_files
      end

      def license_text
        ensure_extracted
        @license_text
      end

      def operations
        ensure_extracted
        @operations.size == 1 ? @operations.first : @operations
      end

      private

      def fetch_extension(file)
        File.extname(filename(file)).sub(/^\./, "")
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
        match_files(path)
        if matched?
          save_operation_subdir
          return path
        end

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
        case fetch_extension(archive).downcase
        when "msi"
          Extractors::OleExtractor.new(archive)
        when "cab"
          Extractors::CabExtractor.new(archive)
        when "exe"
          extractor = Extractors::SevenZipExtractor.new(archive)
          extractor.try ? extractor : Extractors::CabExtractor.new(archive)
        when "zip"
          Extractors::ZipExtractor.new(archive)
        when "rpm"
          Extractors::RpmExtractor.new(archive)
        when "gz"
          Extractors::GzipExtractor.new(archive)
        when "cpio"
          Extractors::CpioExtractor.new(archive)
        when "tar"
          Extractors::TarExtractor.new(archive)
        else
          raise Errors::UnknownArchiveError, "Could not unarchive `#{filename(archive)}`."
        end
      end
      # rubocop:enable Metrics/MethodLength

      def save_operation(extractor)
        @operations << { format: extractor.format }
      end

      def match_files(dir_path)
        Find.find(dir_path) do |entry_path| # rubocop:disable Style/CollectionMethods
          match_license(entry_path)
          match_font(entry_path) if font_directory?(entry_path, dir_path)
        end
      end

      def match_license(path)
        @license_text ||= File.read(path) if license?(path)
      end

      def license?(file)
        file.match?(LICENSE_PATTERN)
      end

      def font_directory?(path, base_path)
        return true unless @subdir

        # https://bugs.ruby-lang.org/issues/10011
        base_path = Pathname.new(base_path)

        relative_path = Pathname.new(path).relative_path_from(base_path).to_s
        dirname = File.dirname(relative_path)
        normalized_pattern = @subdir.chomp("/")
        File.fnmatch?(normalized_pattern, dirname)
      end

      def match_font(path)
        case Files::FontDetector.detect(path)
        when :font
          @font_files << Otf::FontFile.new(path)
        when :collection
          @collection_files << Files::CollectionFile.new(path)
        end
      end

      def matched?
        [@font_files, @collection_files].any? do |files|
          files.size.positive?
        end
      end

      def save_operation_subdir
        return unless @subdir

        @operations.last[:options] ||= {}
        @operations.last[:options][:fonts_sub_dir] = @subdir
      end

      def find_archive(path)
        children = Dir.entries(path) - [".", ".."] # ruby 2.4 compat
        paths = children.map { |file| File.join(path, file) }
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
