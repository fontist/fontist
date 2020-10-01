require "zip"
require "pathname"

module Fontist
  module Utils
    module ZipExtractor
      def zip_extract(resource, download: true, fonts_sub_dir: "", files: nil)
        zip_file = download_file(resource) if download
        zip_file ||= resource.urls.first

        fonts_paths = unzip_fonts(zip_file, files, fonts_sub_dir)
        block_given? ? yield(fonts_paths) : fonts_paths
      end

      alias_method :unzip, :zip_extract

      private

      def unzip_fonts(file, content_files = nil, fonts_sub_dir = "")
        Zip.on_exists_proc = true
        Array.new.tap do |fonts|

          Zip::File.open(file) do |zip_file|
            zip_file.glob("#{fonts_sub_dir}*.{ttf,ttc,otf}").each do |entry|
              if entry.name
                filename = Pathname.new(entry.name).basename.to_s
                next if content_files && !content_files.include?(filename)

                font_path = fonts_path.join(filename)
                fonts.push(font_path.to_s)

                entry.extract(font_path)
              end
            end
          end
        end
      end
    end
  end
end
