require "fontist/downloader"

module Fontist
  module Formulas
    class MsVista < Base
      def fetch
        fonts = extract_ppviewer_fonts
        paths = fonts.grep(/#{font_name}/i)
        paths.empty? ? nil : paths
      end

      private

      def check_user_license_agreement
        unless source.agreement === confirmation
          raise(Fontist::Errors::LicensingError)
        end
      end

      def decompressor
        @decompressor ||= (
          require "libmspack"
          LibMsPack::CabDecompressor.new
        )
      end

      def extract_ppviewer_fonts
        Array.new.tap do |fonts|
          cabbed_fonts.each do |font|
            font_path = fonts_path.join(font.filename).to_s
            decompressor.extract(font, font_path)

            fonts.push(font_path)
          end
        end
      end

      def extract_ppviewer_cab_file
        if !File.exists?(ppviewer_cab) || force_download
          exe_file = decompressor.search(download_exe_file.path)
          decompressor.extract(exe_file.files.next, ppviewer_cab)
        end
      end

      def cabbed_fonts
        extract_ppviewer_cab_file
        grep_cabbed_fonts(decompressor.search(ppviewer_cab).files) || []
      end

      def grep_cabbed_fonts(file)
        Array.new.tap do |fonts|
          while file
            fonts.push(file) if file.filename.match(/.tt|.TT/)
            file = file.next
          end
        end
      end

      def source
        @source ||= Fontist::Source.formulas.msvista
      end

      def download_exe_file
        Fontist::Downloader.download(
          source.urls.first, file_size: source.file_size.to_i, sha: source.sha
        )
      end

      def ppviewer_cab
        @ppviewer_cab ||= Fontist.assets_path.join("ppviewer.cab").to_s
      end
    end
  end
end
