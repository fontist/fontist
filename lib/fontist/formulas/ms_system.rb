module Fontist
  module Formulas
    class MsSystem < Base
      def fetch
        fonts = extract_cabbed_fonts
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

      def extract_cabbed_fonts
        Array.new.tap do |fonts|
          cabbed_fonts.each do |font|
            font_path = fonts_path.join(font.filename).to_s
            decompressor.extract(font, font_path)

            fonts.push(font_path)
          end
        end
      end

      def cabbed_fonts
        exe_file = download_exe_file
        cab_file = decompressor.search(exe_file.path)
        grep_cabbed_fonts(cab_file.files) || []
      end

      def grep_cabbed_fonts(file)
        Array.new.tap do |fonts|
          while file
            fonts.push(file) if file.filename.match(/.tt|.ttc/i)
            file = file.next
          end
        end
      end

      def source
        @source ||= Fontist::Source.formulas.ms_system
      end

      def download_exe_file
        Fontist::Downloader.download(
          source.urls.first, file_size: source.file_size, sha: source.sha,
        )
      end
    end
  end
end
