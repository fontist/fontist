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

      def decompressor
        @decompressor ||= (
          require "libmspack"
          LibMsPack::CabDecompressor.new
        )
      end

      def formulas
        @formulas ||= Fontist::Source.formulas
      end

      def match_fonts(fonts_dir, font_name)
        font = fonts_dir.grep(/#{font_name}/i)
        @matched_fonts.push(font) if font

        font
      end

      def cab_extract(exe_file, download: true,  font_ext: /.tt|.ttc/i)
        exe_file = download_file(exe_file).path if download
        cab_file = decompressor.search(exe_file)
        cabbed_fonts = grep_fonts(cab_file.files, font_ext) || []
        fonts_paths = extract_cabbed_fonts_to_assets(cabbed_fonts)

        yield(fonts_paths) if block_given?
      end

      def grep_fonts(file, font_ext)
        Array.new.tap do |fonts|
          while file
            fonts.push(file) if file.filename.match(font_ext)
            file = file.next
          end
        end
      end

      def extract_cabbed_fonts_to_assets(cabbed_fonts)
        Array.new.tap do |fonts|
          cabbed_fonts.each do |font|
            font_path = fonts_path.join(font.filename).to_s
            decompressor.extract(font, font_path)

            fonts.push(font_path)
          end
        end
      end

      def download_file(source)
        Fontist::Downloader.download(
          source.urls.first, sha: source.sha, file_size: source.file_size,
        )
      end
    end
  end
end
