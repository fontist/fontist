require "fontist/downloader"
require "fontist/formulas/helpers/exe_extractor"
require "fontist/formulas/helpers/zip_extractor"

module Fontist
  module Formulas
    class Base
      def initialize(font_name, confirmation:, **options)
        @matched_fonts = []
        @font_name = font_name
        @confirmation = confirmation || "no"
        @force_download = options.fetch(:force_download, false)
        @fonts_path = options.fetch(:fonts_path, Fontist.fonts_path)

        check_user_license_agreement
      end

      def self.fetch_font(font_name, confirmation: nil, **options)
        new(font_name, options.merge(confirmation: confirmation)).fetch
      end

      def fetch
        extract_fonts([font_name])
        matched_fonts_uniq = matched_fonts.flatten.uniq

        matched_fonts_uniq.empty? ? nil : matched_fonts_uniq
      end

      private

      attr_reader(
        :font_name,
        :fonts_path,
        :confirmation,
        :matched_fonts,
        :force_download,
      )

      def check_user_license_agreement
      end

      def resources(name, &block)
        source = formulas[name]
        block_given? ? yield(source) : source
      end

      def formulas
        @formulas ||= Fontist::Source.formulas
      end

      def match_fonts(fonts_dir, font_name)
        font = fonts_dir.grep(/#{font_name}/i)
        @matched_fonts.push(font) if font

        font
      end

      def download_file(source)
        Fontist::Downloader.download(
          source.urls.first, sha: source.sha, file_size: source.file_size,
        )
      end
    end
  end
end
