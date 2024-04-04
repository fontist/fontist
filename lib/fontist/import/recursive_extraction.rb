require_relative "otf/font_file"
require_relative "files/collection_file"
require_relative "files/font_detector"

module Fontist
  module Import
    class RecursiveExtraction
      LICENSE_PATTERN =
        /(ofl\.txt|ufl\.txt|licenses?\.txt|license(\.md)?|copying)$/i.freeze

      def initialize(archive, subdir: nil, file_pattern: nil)
        @archive = archive
        @subdir = subdir
        @file_pattern = file_pattern
        @operations = {}
        @font_files = []
        @collection_files = []

        save_operation_subdir
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

      def ensure_extracted
        return if @extracted

        extract_data(@archive)
        @extracted = true
      end

      def extract_data(archive)
        Excavate::Archive.new(path(archive)).files(recursive_packages: true) do |path|
          Fontist.ui.debug(path)
          next unless File.file?(path)

          match_license(path)
          match_font(path) if font_candidate?(path)
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
          file = Otf::FontFile.new(path)
          @font_files << file unless already_exist?(file)
        when :collection
          @collection_files << Files::CollectionFile.new(path)
        end
      end

      def already_exist?(candidate)
        @font_files.any? do |file|
          file.family_name == candidate.family_name &&
            file.type == candidate.type &&
            file.version == candidate.version &&
            file.font == candidate.font
        end
      end

      def font_candidate?(path)
        font_directory?(path) && file_pattern?(path)
      end

      def font_directory?(path)
        return true unless subdirectory_pattern

        File.fnmatch?(subdirectory_pattern, File.dirname(path))
      end

      def subdirectory_pattern
        @subdirectory_pattern ||= "*" + @subdir.chomp("/") if @subdir
      end

      def file_pattern?(path)
        return true unless @file_pattern

        File.fnmatch?(@file_pattern, File.basename(path))
      end
    end
  end
end
