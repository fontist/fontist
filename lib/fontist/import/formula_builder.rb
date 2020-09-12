require_relative "text_helper"

module Fontist
  module Import
    class FormulaBuilder
      FORMULA_ATTRIBUTES = %i[name description homepage resources
                              font_collections fonts extract copyright
                              license_url open_license].freeze

      attr_accessor :archive,
                    :url,
                    :extractor,
                    :options,
                    :font_files,
                    :font_collection_files,
                    :license_text

      def initialize
        @options = {}
      end

      def formula
        FORMULA_ATTRIBUTES.map { |name| [name, send(name)] }.to_h.compact
      end

      private

      def name
        return options[:name] if options[:name]

        unique_names = both_fonts.map(&:family_name).uniq
        TextHelper.longest_common_prefix(unique_names) ||
          both_fonts.first.family_name
      end

      def both_fonts
        @both_fonts ||= group_fonts
      end

      def group_fonts
        files = (@font_files + @font_collection_files.map(&:fonts)).flatten
        raise FontNotFoundError, "No font found" if files.empty?

        files
      end

      def description
        name
      end

      def homepage
        both_fonts.first.homepage
      end

      def resources
        filename = name.gsub(" ", "_") + "." + @extractor.extension

        options = { urls: [@url] + (@options[:mirror] || []),
                    sha256: Digest::SHA256.file(@archive).to_s }

        { filename => options }
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
        @extractor.operations
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
