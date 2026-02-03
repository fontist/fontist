require "fontisan"
require_relative "errors"

module Fontist
  class CollectionFile
    include Enumerable

    class << self
      def from_path(path)
        collection = build_collection(path)

        yield new(collection, path)
      end

      private

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def build_collection(path)
        # Validate collection by checking it can be loaded
        # This uses fontisan's collection validation infrastructure
        require "fontisan"

        # First check if it's a valid collection file
        unless Fontisan::FontLoader.collection?(path)
          raise Errors::FontFileError,
                "File is not a recognized font collection (TTC/OTC/dfont)"
        end

        # Check for extension mismatch and issue warning
        check_extension_warning(path)

        # Load the collection to verify structure
        collection = Fontisan::FontLoader.load_collection(path)

        # Validate at least the first font is indexable
        # This provides a basic sanity check that the collection is valid
        validator = Fontisan::Validators::ProfileLoader.load(:indexability)
        first_font = Fontisan::FontLoader.load(path,
                                               font_index: 0,
                                               mode: :metadata,
                                               lazy: true)
        validation_report = validator.validate(first_font)

        unless validation_report.valid?
          error_messages = validation_report.errors.map do |e|
            "#{e.category}: #{e.message}"
          end.join("; ")
          # rubocop:disable Layout/LineLength
          raise Errors::FontFileError,
                "Font collection failed indexability validation (first font): #{error_messages}"
          # rubocop:enable Layout/LineLength
        end

        collection
      rescue StandardError => e
        raise Errors::FontFileError,
              "Font collection could not be loaded: #{e.inspect}."
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength
      def check_extension_warning(path)
        expected_ext = File.extname(path).downcase.sub(/^\./, "")

        # Collection extensions
        collection_extensions = %w[ttc otc dfont]

        unless collection_extensions.include?(expected_ext)
          Fontist.ui.warn(
            # rubocop:disable Layout/LineLength
            "WARNING: File '#{File.basename(path)}' has extension '.#{expected_ext}' " \
            "but appears to be a font collection (.ttc/.otc/.dfont). " \
            "The file will be indexed, but consider renaming for clarity.",
            # rubocop:enable Layout/LineLength
          )
        end
      rescue StandardError => e
        # Don't fail indexing just because we can't detect the format
        Fontist.ui.debug("Could not check extension for warning: #{e.message}")
      end
      # rubocop:enable Metrics/MethodLength
    end

    def initialize(fontisan_collection, path)
      @collection = fontisan_collection
      @path = path
    end

    def count
      @collection.num_fonts
    end

    def each
      count.times do |index|
        yield self[index]
      end

      self
    end

    # Return font metadata for a font in the collection.
    # This uses Fontisan directly to extract metadata without creating tempfiles,
    # which avoids Windows file locking issues.
    def [](index)
      # Load the font directly from the collection using Fontisan's FontLoader
      # mode: :metadata gives us just the metadata tables (faster, less memory)
      # lazy: false means we load the tables immediately (not deferred)
      font = Fontisan::FontLoader.load(@path, font_index: index,
                                              mode: :metadata, lazy: false)

      # Extract font metadata directly from Fontisan's font object
      # This avoids creating tempfiles and loading the font twice
      font_info = extract_font_metadata(font)

      # Create a FontFile-like object to hold the metadata
      # We use a simple struct with accessor methods for compatibility
      FontFileMetadata.new(font_info)
    end

    private

    # Simple metadata container that provides the same interface as FontFile
    # This avoids creating tempfiles while maintaining compatibility with code
    # that expects FontFile objects.
    class FontFileMetadata
      attr_reader :full_name, :family, :subfamily, :preferred_family_name,
                  :preferred_subfamily_name

      def initialize(metadata)
        @full_name = metadata[:full_name]
        @family = metadata[:family_name]
        @subfamily = metadata[:subfamily_name]
        @preferred_family_name = metadata[:preferred_family]
        @preferred_subfamily_name = metadata[:preferred_subfamily]
      end
    end

    # Extract font metadata from a Fontisan font object.
    # Returns a hash with the same structure as FontFile's internal @info hash.
    def extract_font_metadata(font)
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
  end
end
