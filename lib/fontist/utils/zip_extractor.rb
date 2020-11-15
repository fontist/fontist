require "zip"
require "pathname"

module Fontist
  module Utils
    module ZipExtractor
      # fonts_sub_dir is unused now, but formulas have this option
      # rubocop:disable Lint/UnusedMethodArgument
      def zip_extract(resource, download: true, fonts_sub_dir: "")
        zip_file = download_file(resource) if download
        zip_file ||= resource.urls.first

        Fontist.ui.say(%(Installing font "#{key}".))
        fonts_paths = unzip_fonts(zip_file)
        block_given? ? yield(fonts_paths) : fonts_paths
      end
      # rubocop:enable Lint/UnusedMethodArgument

      alias_method :unzip, :zip_extract

      private

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def unzip_fonts(file)
        Zip.on_exists_proc = true

        Array.new.tap do |fonts|
          Zip::File.open(file) do |zip_file|
            zip_file.each do |entry|
              if entry.name
                filename = Pathname.new(entry.name).basename.to_s
                if font_file?(filename)
                  target_filename = target_filename(filename)
                  font_path = fonts_path.join(target_filename)
                  fonts.push(font_path.to_s)

                  entry.extract(font_path)
                end
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
