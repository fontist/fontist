require_relative "otf/font_file"
require_relative "files/collection_file"
require_relative "files/font_detector"

module Fontist
  module Import
    class RecursiveExtraction
      LICENSE_PATTERN =
        /(ofl\.txt|ufl\.txt|licenses?\.txt|license(\.md)?|copying)$/i.freeze

      def initialize(archive, subarchive: nil, subdir: nil)
        @archive = archive
        @subdir = subdir
        @operations = {}
        @font_files = []
        @collection_files = []

        save_operation_subdir
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
        @operations
      end

      private

      def save_operation_subdir
        return unless @subdir

        @operations[:options] ||= {}
        @operations[:options][:fonts_sub_dir] = @subdir
      end

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
        return if @extracted

        extract_data(@archive)
        @extracted = true
      end

      def extract_data(archive)
        Excavate::Archive.new(path(archive)).files(recursive_packages: true) do |path|
          next unless File.file?(path)

          match_license(path)
          match_font(path) if font_directory?(path)
        end
      end

      def path(file)
        file.respond_to?(:path) ? file.path : file
      end

      def match_license(path)
        @license_text ||= File.read(path) if license?(path)
      end

      def license?(file)
        file.match?(LICENSE_PATTERN)
      end

      def match_font(path)
        case Files::FontDetector.detect(path)
        when :font
          @font_files << Otf::FontFile.new(path)
        when :collection
          @collection_files << Files::CollectionFile.new(path)
        end
      end

      def font_directory?(path)
        return true unless subdirectory_pattern

        File.fnmatch?(subdirectory_pattern, File.dirname(path))
      end

      def subdirectory_pattern
        @subdirectory_pattern ||= "*" + @subdir.chomp("/") if @subdir
      end
    end
  end
end
