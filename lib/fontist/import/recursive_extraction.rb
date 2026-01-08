require_relative "otf/font_file"
require_relative "files/collection_file"
require_relative "files/font_detector"
require_relative "font_parsing_error_collector"

module Fontist
  module Import
    class RecursiveExtraction
      LICENSE_PATTERN =
        /(ofl\.txt|ufl\.txt|licenses?\.txt|license(\.md)?|copying)$/i.freeze

      # Font extensions that are recognized during extraction
      # This is displayed to users so they understand what files are being matched
      SUPPORTED_FONT_EXTENSIONS = %w[ttf otf ttc otc woff woff2 dfont].freeze
      FONT_EXTENSIONS_PATTERN = /\.(#{SUPPORTED_FONT_EXTENSIONS.join('|')})$/i.freeze

      attr_reader :error_collector

      def initialize(archive, subdir: nil, file_pattern: nil, name_prefix: nil, verbose: false)
        @archive = archive
        @subdir = subdir
        @file_pattern = file_pattern
        @name_prefix = name_prefix
        @verbose = verbose
        @operations = {}
        @font_files = []
        @collection_files = []
        @error_collector = FontParsingErrorCollector.new

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

      def error_collector
        @error_collector
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
        extraction_dir_shown = false
        Excavate::Archive.new(path(archive)).files(recursive_packages: true) do |path|
          # Show extraction directory once in verbose mode
          if @verbose && !extraction_dir_shown && File.file?(path)
            extraction_dir = File.dirname(path)
            Fontist.ui.say("  Extracting to: #{Paint[extraction_dir, :black, :bright]}")
            extraction_dir_shown = true
          end

          Fontist.ui.say("  #{Paint[path, :black, :bright]}") if @verbose
          next unless File.file?(path)

          match_license(path)
          match_font(path) if font_candidate?(path)
        end

        # Notify when extraction cache is cleared (verbose mode only)
        Fontist.ui.say("  Extraction cache cleared") if @verbose
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
        case Files::FontDetector.detect(path, error_collector: @error_collector)
        when :font
          file = Otf::FontFile.new(path, name_prefix: @name_prefix)
          @font_files << file unless already_exist?(file)
        when :collection
          collection = Files::CollectionFile.from_path(path, name_prefix: @name_prefix, error_collector: @error_collector)
          if collection
            @collection_files << collection
          else
            # Collection could not be parsed - already logged by CollectionFile
            Fontist.ui.debug("Skipping unparseable collection: #{File.basename(path)}")
          end
        end
      rescue StandardError => e
        # Log error but continue processing other fonts
        Fontist.ui.debug("Error processing font #{File.basename(path)}: #{e.message}")
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
        has_font_extension?(path) && font_directory?(path) && file_pattern?(path)
      end

      def has_font_extension?(path)
        path.match?(FONT_EXTENSIONS_PATTERN)
      end

      def font_directory?(path)
        return true unless subdirectory_pattern

        File.fnmatch?(subdirectory_pattern, File.dirname(path))
      end

      def subdirectory_pattern
        @subdirectory_pattern ||= "*#{@subdir.chomp('/')}" if @subdir
      end

      def file_pattern?(path)
        return true unless @file_pattern

        File.fnmatch?(@file_pattern, File.basename(path))
      end
    end
  end
end
