require "zip"

module Fontist
  module Formulas
    module Helpers
      module ZipExtractor
        def zip_extract(resource, download: true, fonts_sub_dir: "")
          zip_file = download_file(resource) if download
          zip_file ||= resource.urls.first

          fonts_paths = unzip_fonts(zip_file, fonts_sub_dir)
          block_given? ? yield(fonts_paths) : fonts_paths
        end

        private

        def unzip_fonts(file, fonts_sub_dir = "")
          Zip.on_exists_proc = true

          Array.new.tap do |fonts|
            Zip::File.open(file) do |zip_file|
              zip_file.glob("#{fonts_sub_dir}*.{ttf,ttc,otf}").each do |entry|
                filename = entry.name.gsub("#{fonts_sub_dir}", "")

                if filename
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
end
