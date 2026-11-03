require "fontisan"
require "tempfile"

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
          # Load the first font in the collection
          font = Fontisan::FontLoader.load(path, font_index: 0,
                                                 mode: :metadata, lazy: true)

          # Validate the font using indexability profile (log issues but don't reject)
          validator = load_indexability_validator
          validation_report = validator.validate(font)

          unless validation_report.valid?
            error_messages = validation_report.errors.map do |e|
              "#{e.category}: #{e.message}"
            end.join("; ")
            Fontist.ui.debug(
              "Font validation issues for #{File.basename(path)}: #{error_messages}",
            )
          end

        else
          # Single font - validate and load
          font = validate_and_load_single_font(path)
        end
        names = extract_names_from_font(font)
        # `has_table?` consults the table directory, which survives the
        # metadata-mode load, so the fvar check is cheap; only an actual
        # variable font pays for the follow-up full read. WOFF and WOFF2
        # fonts from Fontisan hold no open file to close.
        variable = font.has_table?("fvar")
        font.close if font.respond_to?(:close)
        names[:variable_instances] = extract_variable_instances_from_path(path) if
          variable && names[:family_name]
        names
      rescue StandardError => e
        raise_font_file_error(e)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def extract_variable_instances_from_path(path)
        # Full mode: the metadata-mode loader gates fvar data out, so the
        # instance pass needs the real table read; this runs only for
        # fonts already identified as variable by the cheap directory check.
        font = Fontisan::FontLoader.load(path, mode: :full, lazy: true)
        extract_variable_instances(font)
      ensure
        font.close if font.respond_to?(:close)
      end

      # rubocop:disable Metrics/MethodLength
      def validate_and_load_single_font(path)
        # Load font first (we need to validate it, not the file path)
        font = Fontisan::FontLoader.load(path, mode: :metadata, lazy: true)

        # Validate the font using indexability profile
        validator = load_indexability_validator
        validation_report = validator.validate(font)

        unless validation_report.valid?
          # Log validation issues but don't reject outright
          # We'll check if we can still extract metadata
          error_messages = validation_report.errors.map do |e|
            "#{e.category}: #{e.message}"
          end.join("; ")
          Fontist.ui.debug(
            "Font validation issues for #{File.basename(path)}: #{error_messages}",
          )
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

      def detect_font_format(path)
        format = Fontisan::FontLoader.detect_format(path)
        format ? format.to_s : "unknown"
      rescue StandardError
        "unknown"
      end

      # rubocop:disable Metrics/MethodLength
      def extract_names_from_font(font)
        # Access name table directly
        name_table = font.table(Fontisan::Constants::NAME_TAG)
        return {} unless name_table

        # Extract all needed name strings using Fontisan's API
        # Fall back to non-English names if English names are not available
        {
          full_name: name_table.english_name(Fontisan::Tables::Name::FULL_NAME) ||
            extract_any_name(name_table, Fontisan::Tables::Name::FULL_NAME),
          family_name: name_table.english_name(Fontisan::Tables::Name::FAMILY) ||
            extract_any_name(name_table, Fontisan::Tables::Name::FAMILY),
          subfamily_name: name_table.english_name(Fontisan::Tables::Name::SUBFAMILY) ||
            extract_any_name(name_table, Fontisan::Tables::Name::SUBFAMILY),
          preferred_family: name_table.english_name(Fontisan::Tables::Name::PREFERRED_FAMILY) ||
            extract_any_name(name_table, Fontisan::Tables::Name::PREFERRED_FAMILY),
          preferred_subfamily: name_table.english_name(Fontisan::Tables::Name::PREFERRED_SUBFAMILY) ||
            extract_any_name(name_table, Fontisan::Tables::Name::PREFERRED_SUBFAMILY),
          postscript_name: name_table.english_name(Fontisan::Tables::Name::POSTSCRIPT_NAME) ||
            extract_any_name(name_table, Fontisan::Tables::Name::POSTSCRIPT_NAME),
        }
      end
      # rubocop:enable Metrics/MethodLength

      # Named instances of a variable font, as `{family:, style:, full_name:}`
      # triples. A variable file carries every named instance in one fvar
      # table, but its name table exposes only the default instance's
      # family, so an index built from the name table alone registers the
      # file under a single family ("Fira Code Light") and every lookup of
      # the other families/styles misses it. The RIBBI mapping follows the
      # convention static families use: Regular/Bold live on the base
      # family, every other weight becomes its own "Base Weight" family.
      #
      # @return [Array<Hash>] empty for a static font
      # rubocop:disable Metrics/MethodLength
      def extract_variable_instances(font)
        return [] unless font.has_table?("fvar")

        fvar = font.table("fvar")
        name_table = font.table(Fontisan::Constants::NAME_TAG)
        return [] unless name_table

        base = name_table.english_name(Fontisan::Tables::Name::PREFERRED_FAMILY) ||
          extract_any_name(name_table, Fontisan::Tables::Name::PREFERRED_FAMILY) ||
          name_table.english_name(Fontisan::Tables::Name::FAMILY)
        return [] unless base

        ribbi = ["regular", "bold", "italic", "bold italic"]

        fvar.instances.filter_map do |instance|
          # fvar yields plain hashes ({name_id:, flags:, coordinates:,
          # postscript_name_id:}), not message objects.
          style = name_table.english_name(instance[:name_id]) ||
            extract_any_name(name_table, instance[:name_id])
          next unless style

          if ribbi.include?(style.downcase)
            family = base
            type = style
            full_name = "#{family} #{style}"
          else
            family = "#{base} #{style}"
            type = "Regular"
            full_name = family
          end

          {
            family: family,
            style: type,
            full_name: full_name,
          }
        end
      rescue StandardError => e
        Fontist.ui.debug(
          "Could not read variable instances: #{e.message}",
        )
        []
      end
      # rubocop:enable Metrics/MethodLength

      # Extract any available name for a given name ID by manually decoding the name record
      def extract_any_name(name_table, name_id)
        # Find any name record with the matching name_id
        records = name_table.name_records.select { |r| r.name_id == name_id }
        return nil if records.empty?

        # Manually decode each record
        records.each do |record|
          decoded = decode_name_record_manually(name_table, record)
          return decoded unless decoded.nil? || decoded.empty?
        end

        nil
      end

      # Manually decode a name record since the fontisan method is private
      def decode_name_record_manually(name_table, record)
        # Get raw string storage
        storage_bytes = name_table.string_storage.to_s.b

        # Extract this record's string
        offset = record.string_offset
        length = record.string_length

        return nil if offset + length > storage_bytes.bytesize
        return nil if length.zero?

        string_data = storage_bytes.byteslice(offset, length)

        # Decode based on platform (same logic as fontisan)
        case record.platform_id
        when 0, 3 # PLATFORM_UNICODE, PLATFORM_WINDOWS
          string_data.dup.force_encoding("UTF-16BE")
            .encode("UTF-8", invalid: :replace, undef: :replace)
        when 1 # PLATFORM_MACINTOSH
          string_data.dup.force_encoding("ASCII-8BIT")
            .encode("UTF-8", invalid: :replace, undef: :replace)
        else
          string_data.dup.force_encoding("UTF-8")
        end
      end

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

    # Named instances of a variable font (`{family:, style:, full_name:}`
    # triples); empty for a static font.
    def variable_instances
      @info[:variable_instances] || []
    end
  end
end
