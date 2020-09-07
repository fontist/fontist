require_relative "text_helper"

module Fontist
  module Import
    class FormulaBuilder
      FORMULA_ATTRIBUTES = %i[name description homepage resources
                              font_collections fonts extract copyright
                              license_url open_license].freeze

      BOTH_FONTS_PATTERN = "**/*.{ttf,otf,ttc}".freeze

      attr_accessor :archive,
                    :url,
                    :font_files,
                    :font_collection_files,
                    :license_text

      def formula
        FORMULA_ATTRIBUTES.map { |name| [name, send(name)] }.to_h.compact
      end

      private

      def name
        unique_names = both_fonts.map(&:family_name).uniq
        TextHelper.longest_common_prefix(unique_names).strip
      end

      def both_fonts
        @both_fonts ||= (@font_files +
                         @font_collection_files.map(&:fonts)).flatten
      end

      def description
        name
      end

      def homepage
        both_fonts.first.homepage
      end

      def resources
        cleanname = name.gsub(" ", "_")
        extension = File.extname(archive_filename)
        filename = cleanname + extension

        options = { urls: [@url],
                    sha256: Digest::SHA256.file(@archive).to_s }

        { filename => options }
      end

      def archive_filename
        if @archive.respond_to?(:original_filename)
          @archive.original_filename
        else
          File.basename(@archive)
        end
      end

      def font_collections
        return if @font_collection_files.empty?

        collections = @font_collection_files.map do |file|
          fonts = fonts_from_files(file.fonts, :to_collection_style)
          { filename: file.filename, fonts: fonts }
        end

        collections.sort_by do |x|
          x[:filename]
        end
      end

      def fonts
        return if @font_files.empty?

        fonts_from_files(@font_files, :to_style)
      end

      def fonts_from_files(files, style_type = :to_style)
        groups = files.group_by(&:family_name)

        fonts = groups.map do |name, group|
          { name: name,
            styles: group.map(&style_type) }
        end

        fonts.sort_by do |x|
          x[:name]
        end
      end

      def extract
        format = File.extname(archive_filename).sub(/^\./, "")

        zip_file = Zip::File.open(@archive)
        sub_dirs = zip_file.glob(BOTH_FONTS_PATTERN).map do |entry|
          File.split(entry.name).first
        end

        options = { fonts_sub_dir: "**/*/" } unless sub_dirs.uniq == ["."]

        { format: format, options: options }.compact
      end

      def copyright
        both_fonts.first.copyright
      end

      def license_url
        both_fonts.first.license_url
      end

      def open_license
        return unless @license_text

        TextHelper.cleanup(@license_text)
      end
    end
  end
end
