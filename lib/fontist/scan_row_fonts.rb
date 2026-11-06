module Fontist
  # Turns `Fontisan.scan` rows into the font objects the indexes already
  # consume (`FontFile` for single fonts, a `FontFile` over the english-only
  # names for collection faces), so one batch scan can replace the per-path
  # `FontFile.from_path` / `CollectionFile.from_path` loads.
  #
  # Only rows that carry no error are usable; anything else is left to the
  # per-file path so its message stays byte-identical.
  module ScanRowFonts
    SINGLE_FORMATS = %w[ttf otf woff woff2].freeze
    COLLECTION_FORMATS = %w[ttc otc].freeze

    class << self
      def usable?(rows)
        return false if rows.nil? || rows.empty?

        if rows.first["is_collection"]
          collection_usable?(rows)
        else
          single_usable?(rows)
        end
      end

      def file_font(row)
        report_validation(row)
        info = symbolize(row["names"] || {})
        if row["has_fvar"] && info[:family_name]
          info[:variable_instances] =
            row["variable_instances"].map { |i| symbolize(i) }
        end
        FontFile.new(info)
      end

      def collection_face(row)
        FontFile.new(symbolize(row["english_names"] || {}))
      end

      def warn_file_extension(path, row)
        FontFile.check_extension_warning(path, row["is_collection"])
      end

      def warn_collection_extension(path)
        CollectionFile.send(:check_extension_warning, path)
      end

      private

      def collection_usable?(rows)
        COLLECTION_FORMATS.include?(rows.first["format"]) &&
          rows.all? { |row| collection_row_ok?(row) }
      end

      def single_usable?(rows)
        row = rows.first
        rows.size == 1 && SINGLE_FORMATS.include?(row["format"]) &&
          row["errors"]["font_file"].nil? && !row["names"].nil?
      end

      def symbolize(hash)
        hash.transform_keys(&:to_sym)
      end

      def collection_row_ok?(row)
        row["is_collection"] && row["num_faces"].to_i.positive? &&
          row["errors"]["collection_file"].nil? &&
          row["errors"]["collection_member"].nil?
      end

      def report_validation(row)
        validation = row["validation"]
        return if validation.nil? || validation["valid"]

        name = File.basename(row["path"])
        Fontist.ui.debug(
          "Font validation issues for #{name}: #{validation['error_summary']}",
        )
      end
    end
  end
end
