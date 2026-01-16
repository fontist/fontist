require "fontisan"
require "tempfile"
require_relative "errors"

module Fontist
  class FontFile
    class << self
      def from_path(path)
        font_info = extract_font_info_from_path(path)
        new(font_info)
      end

      # rubocop:disable Metrics/MethodLength
      def from_content(content)
        tmpfile = Tempfile.new(["font", ".ttf"])
        tmpfile.binmode
        tmpfile.write(content)
        tmpfile.flush
        tmpfile.close

        font_info = extract_font_info_from_path(tmpfile.path)
        # Keep tempfile alive to prevent GC issues on Windows
        # rubocop:disable Layout/LineLength
        # Return both the font object and tempfile so caller can keep it referenced
        # rubocop:enable Layout/LineLength
        new(font_info, tmpfile)
      rescue StandardError => e
        raise_font_file_error(e)
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def extract_font_info_from_path(path)
        # rubocop:disable Layout/LineLength
        # First, detect if the file is actually a collection (regardless of extension)
        # rubocop:enable Layout/LineLength
        # This handles cases where .ttf files are actually .ttc collections
        is_collection = Fontisan::FontLoader.collection?(path)

        # Check for extension mismatch and issue warning
        check_extension_warning(path, is_collection)

        # For collections, we need different handling
        if is_collection
          # Load and validate the first font in the collection for indexability
          font = Fontisan::FontLoader.load(path, font_index: 0,
                                                 mode: :metadata, lazy: true)

          # Validate the font using indexability profile
          validator = load_indexability_validator
          validation_report = validator.validate(font)

          unless validation_report.valid?
            error_messages = validation_report.errors.map do |e|
              "#{e.category}: #{e.message}"
            end.join("; ")
            # rubocop:disable Layout/LineLength
            raise Errors::FontFileError,
                  "Font from collection failed indexability validation: #{error_messages}"
            # rubocop:enable Layout/LineLength
          end

        else
          # Single font - validate and load
          font = validate_and_load_single_font(path)
        end
        extract_names_from_font(font)
      rescue StandardError => e
        raise_font_file_error(e)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      def validate_and_load_single_font(path)
        # Load font first (we need to validate it, not the file path)
        font = Fontisan::FontLoader.load(path, mode: :metadata, lazy: true)

        # Validate the font using indexability profile
        validator = load_indexability_validator
        validation_report = validator.validate(font)

        unless validation_report.valid?
          error_messages = validation_report.errors.map do |e|
            "#{e.category}: #{e.message}"
          end.join("; ")
          raise Errors::FontFileError,
                "Font file failed indexability validation: #{error_messages}"
        end

        font
      end
      # rubocop:enable Metrics/MethodLength

      def load_indexability_validator
        Fontisan::Validators::ProfileLoader.load(:indexability)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def check_extension_warning(path, is_collection)
        expected_ext = File.extname(path).downcase.sub(/^\./, "")

        # Determine actual format based on content
        actual_format = if is_collection
                          # Use ttc as generic collection extension
                          "ttc"
                        else
                          detect_font_format(path)
                        end

        # Map common collection extensions to "ttc"
        collection_extensions = %w[ttc otc dfont]
        is_expected_collection = collection_extensions.include?(expected_ext)

        # Check for mismatch
        if is_collection && !is_expected_collection
          Fontist.ui.warn(
            # rubocop:disable Layout/LineLength
            "WARNING: File '#{File.basename(path)}' has extension '.#{expected_ext}' " \
            "but appears to be a font collection (.ttc/.otc/.dfont). " \
            "The file will be indexed, but consider renaming for clarity.",
            # rubocop:enable Layout/LineLength
          )
        elsif !is_collection && is_expected_collection
          # File has collection extension but is actually a single font
          Fontist.ui.warn(
            # rubocop:disable Layout/LineLength
            "WARNING: File '#{File.basename(path)}' has collection extension '.#{expected_ext}' " \
            "but appears to be a single font (.#{actual_format}). " \
            "The file will be indexed, but consider renaming for clarity.",
            # rubocop:enable Layout/LineLength
          )
        elsif !is_collection && expected_ext != actual_format
          # Single font with wrong format extension
          Fontist.ui.warn(
            # rubocop:disable Layout/LineLength
            "WARNING: File '#{File.basename(path)}' has extension '.#{expected_ext}' " \
            "but appears to be a #{actual_format.upcase} font. " \
            "The file will be indexed, but consider renaming for clarity.",
            # rubocop:enable Layout/LineLength
          )
        end
      rescue StandardError => e
        # Don't fail indexing just because we can't detect the format
        # rubocop:disable Layout/LineLength
        Fontist.ui.debug("Could not detect file format for warning: #{e.message}")
        # rubocop:enable Layout/LineLength
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      # rubocop:disable Metrics/MethodLength
      def detect_font_format(path)
        # Open file and check SFNT version to determine actual format
        File.open(path, "rb") do |io|
          signature = io.read(4)
          io.rewind

          case signature
          when "\x00\x01\x00\x00", "true"
            "ttf"
          when "OTTO"
            "otf"
          when "wOFF"
            "woff"
          when "wOF2"
            "woff2"
          else
            "unknown"
          end
        end
      rescue StandardError
        "unknown"
      end

      # rubocop:disable Metrics/MethodLength
      def extract_names_from_font(font)
        # Access name table directly
        name_table = font.table(Fontisan::Constants::NAME_TAG)
        return {} unless name_table

        # Extract all needed name strings using Fontisan's API
        {
          full_name: name_table.english_name(Fontisan::Tables::Name::FULL_NAME),
          family_name: name_table.english_name(Fontisan::Tables::Name::FAMILY),
          subfamily_name: name_table.english_name(Fontisan::Tables::Name::SUBFAMILY),
          preferred_family: name_table.english_name(Fontisan::Tables::Name::PREFERRED_FAMILY),
          preferred_subfamily: name_table.english_name(Fontisan::Tables::Name::PREFERRED_SUBFAMILY),
          postscript_name: name_table.english_name(Fontisan::Tables::Name::POSTSCRIPT_NAME),
        }
      end
      # rubocop:enable Metrics/MethodLength

      def raise_font_file_error(exception)
        raise Errors::FontFileError,
              "Font file could not be parsed: #{exception.inspect}."
      end
    end

    def initialize(font_info, tempfile = nil)
      @info = font_info
      # Keep tempfile alive to prevent GC issues on Windows
      @tempfile = tempfile
    end

    def full_name
      @info[:full_name]
    end

    def family
      @info[:family_name]
    end

    def subfamily
      @info[:subfamily_name]
    end

    def preferred_family_name
      @info[:preferred_family]
    end

    def preferred_subfamily_name
      @info[:preferred_subfamily]
    end
  end
end
