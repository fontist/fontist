require "shellwords"
require_relative "text_helper"

module Fontist
  module Import
    class FormulaBuilder
      FORMULA_ATTRIBUTES = %i[description homepage resources
                              font_collections fonts extract copyright
                              license_url open_license digest command].freeze

      attr_writer :archive,
                  :url,
                  :extractor,
                  :options,
                  :font_files,
                  :font_collection_files,
                  :license_text,
                  :homepage

      def initialize
        @options = {}
      end

      def formula
        formula_attributes.map { |name| [name, send(name)] }.to_h.compact
      end

      def name
        return @options[:name] if @options[:name]

        unique_names = both_fonts.map(&:family_name).uniq
        TextHelper.longest_common_prefix(unique_names) ||
          both_fonts.first.family_name
      end

      private

      def formula_attributes
        FORMULA_ATTRIBUTES
      end

      def both_fonts
        @both_fonts ||= group_fonts
      end

      def group_fonts
        files = (@font_files + @font_collection_files.map(&:fonts)).flatten
        raise Errors::FontNotFoundError, "No font found" if files.empty?

        files
      end

      def description
        name
      end

      def homepage
        @options[:homepage] || both_fonts.map(&:homepage).compact.first
      end

      def resources
        filename = name.gsub(" ", "_") + "." + @extractor.extension

        { filename => resource_options }
      end

      def resource_options
        if @options[:skip_sha]
          resource_options_without_sha
        else
          resource_options_with_sha
        end
      end

      def resource_options_without_sha
        { urls: [@url] + mirrors, file_size: file_size }
      end

      def resource_options_with_sha
        urls = []
        sha = []
        downloads do |url, path|
          urls << url
          sha << Digest::SHA256.file(path).to_s
        end

        sha = prepare_sha256(sha)

        { urls: urls, sha256: sha, file_size: file_size }
      end

      def downloads
        yield @url, @archive

        mirrors.each do |url|
          path = download(url)
          next unless path

          yield url, path
        end
      end

      def mirrors
        @options[:mirror] || []
      end

      def download(url)
        Fontist::Utils::Downloader.download(url, progress_bar: true).path
      rescue Errors::InvalidResourceError
        Fontist.ui.error("WARN: a mirror is not found '#{url}'")
        nil
      end

      def prepare_sha256(input)
        output = input.uniq
        return output.first if output.size == 1

        checksums = output.join(", ")
        Fontist.ui.error("WARN: SHA256 differs (#{checksums})")
        output
      end

      def file_size
        File.size(@archive)
      end

      def font_collections
        return if @font_collection_files.empty?

        collections = @font_collection_files.map do |file|
          fonts = fonts_from_files(file.fonts, :to_collection_style)

          { filename: file.filename,
            source_filename: file.source_filename,
            fonts: fonts }.compact
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
            styles: styles_from_files(group, style_type) }
        end

        fonts.sort_by do |x|
          x[:name]
        end
      end

      def styles_from_files(files, style_type)
        files.map(&style_type).sort_by { |x| x[:type] }
      end

      def extract
        @extractor.operations
      end

      def copyright
        both_fonts.map(&:copyright).compact.first
      end

      def license_url
        both_fonts.map(&:license_url).compact.first
      end

      def open_license
        unless @license_text
          Fontist.ui.error("WARN: please add license manually")
          return
        end

        Fontist.ui.error("WARN: ensure it's an open license, otherwise " \
                         "change the 'open_license' attribute to " \
                         "'requires_license_agreement'")

        TextHelper.cleanup(@license_text)
      end

      def digest
        @options[:digest]
      end

      def command
        Shellwords.shelljoin(ARGV)
      end
    end
  end
end
