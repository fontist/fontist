require "fontisan"
require "tempfile"
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

      def build_collection(path)
        # Validate collection by checking it can be loaded and fonts can be extracted
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
        first_font = Fontisan::FontLoader.load(path, font_index: 0, mode: :metadata, lazy: true)
        validation_report = validator.validate(first_font)

        unless validation_report.valid?
          error_messages = validation_report.errors.map { |e| "#{e.category}: #{e.message}" }.join("; ")
          raise Errors::FontFileError,
                "Font collection failed indexability validation (first font): #{error_messages}"
        end

        collection
      rescue StandardError => e
        raise Errors::FontFileError,
              "Font collection could not be loaded: #{e.inspect}."
      end

      def check_extension_warning(path)
        expected_ext = File.extname(path).downcase.sub(/^\./, "")

        # Collection extensions
        collection_extensions = %w[ttc otc dfont]

        unless collection_extensions.include?(expected_ext)
          Fontist.ui.warn(
            "WARNING: File '#{File.basename(path)}' has extension '.#{expected_ext}' " \
            "but appears to be a font collection (.ttc/.otc/.dfont). " \
            "The file will be indexed, but consider renaming for clarity."
          )
        end
      rescue StandardError => e
        # Don't fail indexing just because we can't detect the format
        Fontist.ui.debug("Could not check extension for warning: #{e.message}")
      end
    end

    def initialize(fontisan_collection, path)
      @collection = fontisan_collection
      @path = path
      # Keep tempfiles alive during font extraction to prevent Windows GC issues
      # On Windows, GC finalizers trying to delete files can fail with EACCES
      # if files are still being accessed. By keeping references, we let Ruby's
      # normal GC handle cleanup when the CollectionFile is no longer referenced.
      @tempfiles = []
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

    def [](index)
      # Extract font from collection to temporary file,
      # then load and extract metadata
      tmpfile = Tempfile.new(["font", ".ttf"])
      tmpfile.binmode

      File.open(@path, "rb") do |io|
        # Get font from collection
        font = @collection.font(index, io)

        # Write to tempfile
        font.to_file(tmpfile.path)
      end

      tmpfile.close

      # Keep tempfile alive to prevent GC issues on Windows
      @tempfiles << tmpfile

      # Load and extract metadata using FontFile
      # Tempfile will be deleted when CollectionFile is GC'd
      FontFile.from_path(tmpfile.path)
    end

    # Removed extract_font_info method - now using FontFile.from_path
  end
end
