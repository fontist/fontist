require "fontisan"
require_relative "../otf/font_file"

module Fontist
  module Import
    module Files
      class CollectionFile
        class << self
          def from_path(path, name_prefix: nil, error_collector: nil)
            collection = build_collection(path,
                                          error_collector: error_collector)
            return nil unless collection

            new(collection, path, name_prefix)
          rescue StandardError => e
            # rubocop:disable Layout/LineLength
            Fontist.ui.debug("Failed to build collection from #{File.basename(path)}: #{e.message}")
            # rubocop:enable Layout/LineLength
            nil
          end

          private

          def build_collection(path, error_collector: nil)
            # Use FontLoader to properly detect and load any collection type
            # (TTC, OTC, dfont, etc.)
            Fontisan::FontLoader.load_collection(path)
          rescue StandardError => e
            # Collect error if collector provided, otherwise just debug log
            error_collector&.add(path, e.message, backtrace: e.backtrace)
            # rubocop:disable Layout/LineLength
            Fontist.ui.debug("Fontisan collection load failed for #{File.basename(path)}: #{e.message}")
            # rubocop:enable Layout/LineLength
            nil
          end
        end

        attr_reader :fonts

        def initialize(fontisan_collection, path, name_prefix = nil)
          @collection = fontisan_collection
          @path = path
          @name_prefix = name_prefix
          @fonts = extract_fonts
        end

        def filename
          # rubocop:disable Layout/LineLength
          # Use the exact filename from the archive - do NOT modify or standardize it
          # rubocop:enable Layout/LineLength
          File.basename(@path)
        end

        def source_filename
          # source_filename is only used when filename != original filename
          # Since we now use exact filename, this should always be nil
          nil
        end

        private

        def extract_fonts
          Array.new(@collection.num_fonts) do |index|
            extract_font_at(index)
          end.compact # Remove nil entries from failed extractions
        end

        # rubocop:disable Metrics/MethodLength
        def extract_font_at(index)
          # Load the font directly from the collection using Fontisan.
          # rubocop:disable Layout/LineLength
          # This avoids creating tempfiles and prevents Windows file locking issues.
          # mode: :metadata loads only metadata tables (faster, less memory)
          # rubocop:enable Layout/LineLength
          font = Fontisan::FontLoader.load(@path,
                                           font_index: index,
                                           mode: :metadata,
                                           lazy: false)

          # Build metadata directly from the Fontisan font object
          metadata = build_metadata_from_font(font)

          # rubocop:disable Layout/LineLength
          # Create Otf::FontFile with pre-built metadata (no tempfile needed)
          # Use collection path as the "path" for reference, but metadata comes from the font
          # rubocop:enable Layout/LineLength
          Otf::FontFile.new(@path, name_prefix: @name_prefix,
                                   metadata: metadata)
        rescue StandardError => e
          # rubocop:disable Layout/LineLength
          Fontist.ui.debug("Failed to extract font at index #{index} from #{File.basename(@path)}: #{e.message}")
          # rubocop:enable Layout/LineLength
          nil
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Layout/LineLength
        # Build FontMetadata from a Fontisan font object.
        # This is used when extracting fonts from collections without creating tempfiles.
        # rubocop:enable Layout/LineLength
        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def build_metadata_from_font(font)
          name_table = font.table(Fontisan::Constants::NAME_TAG)
          return unless name_table

          # Preload tables needed for metadata
          font.table(Fontisan::Constants::OS2_TAG)
          font.table(Fontisan::Constants::HEAD_TAG)

          Import::Models::FontMetadata.new(
            family_name: name_table.english_name(Fontisan::Tables::Name::FAMILY),
            subfamily_name: name_table.english_name(Fontisan::Tables::Name::SUBFAMILY),
            full_name: name_table.english_name(Fontisan::Tables::Name::FULL_NAME),
            postscript_name: name_table.english_name(Fontisan::Tables::Name::POSTSCRIPT_NAME),
            preferred_family_name: name_table.english_name(Fontisan::Tables::Name::PREFERRED_FAMILY),
            preferred_subfamily_name: name_table.english_name(Fontisan::Tables::Name::PREFERRED_SUBFAMILY),
            version: clean_version(name_table.english_name(Fontisan::Tables::Name::VERSION)),
            copyright: name_table.english_name(Fontisan::Tables::Name::COPYRIGHT),
            description: name_table.english_name(Fontisan::Tables::Name::LICENSE_DESCRIPTION),
            vendor_url: name_table.english_name(Fontisan::Tables::Name::VENDOR_URL),
            license_url: name_table.english_name(Fontisan::Tables::Name::LICENSE_URL),
            font_format: detect_font_format(font),
            is_variable: font.has_table?(Fontisan::Constants::FVAR_TAG),
          )
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        def detect_font_format(font)
          case font
          when Fontisan::TrueTypeFont
            "truetype"
          when Fontisan::OpenTypeFont
            "cff"
          else
            "unknown"
          end
        end

        def clean_version(version)
          return nil unless version

          version.to_s.gsub(/^Version\s+/i, "")
        end

        def hidden?(font_file)
          font_file.family_name.start_with?(".")
        end
      end
    end
  end
end
