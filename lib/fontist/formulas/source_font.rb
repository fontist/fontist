require "zip"

module Fontist
  module Formulas
    class SourceFont < Formulas::Base
      def fetch
        paths = extract_fonts.grep(/#{font_name}/i)
        paths.empty? ? nil : paths
      end

      private

      def source
        @source ||= Fontist::Source.formulas.source_font
      end

      def extract_fonts
        zip_file = download_file
        unzip_fonts(zip_file)
      end

      def unzip_fonts(file)
        Zip.on_exists_proc = true

        Array.new.tap do |fonts|
          Zip::File.open(file) do |zip_file|
            zip_file.glob("fonts/*.ttf").each do |entry|
              filename = entry.name.gsub("fonts/", "")

              if filename
                font_path = fonts_path.join(filename)
                fonts.push(font_path.to_s)

                entry.extract(font_path)
              end
            end
          end
        end
      end

      def download_file
        Fontist::Downloader.download(
          source.urls.first, file_size: source.file_size.to_i, sha: source.sha
        )
      end
    end
  end
end
