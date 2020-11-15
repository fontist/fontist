module Fontist
  module Utils
    module ExeExtractor
      def cab_extract(exe_file, download: true, font_ext: /.ttf|.otf|.ttc/i)
        download = @downloaded === true ? false : download

        exe_file = download_file(exe_file).path if download

        Fontist.ui.say(%(Installing font "#{key}".))
        cab_file = decompressor.search(exe_file)
        cabbed_fonts = grep_fonts(cab_file.files) || []
        fonts_paths = extract_cabbed_fonts_to_assets(cabbed_fonts)

        block_given? ? yield(fonts_paths) : fonts_paths
      end

      def exe_extract(source, subarchive: nil)
        cab_file = decompressor.search(download_file(source).path)
        subarchive_path = extract_subarchive(cab_file.files, subarchive)
        block_given? ? yield(subarchive_path) : subarchive_path
      end

      private

      def decompressor
        @decompressor ||= (
          require "libmspack"
          LibMsPack::CabDecompressor.new
        )
      end

      def grep_fonts(file)
        Array.new.tap do |fonts|
          while file
            fonts.push(file) if font_file?(file.filename)
            file = file.next
          end
        end
      end

      def extract_cabbed_fonts_to_assets(cabbed_fonts)
        Array.new.tap do |fonts|
          cabbed_fonts.each do |font|
            target_filename = target_filename(font.filename)
            font_path = fonts_path.join(target_filename).to_s
            decompressor.extract(font, font_path)

            fonts.push(font_path)
          end
        end
      end

      def extract_subarchive(file, subarchive = nil)
        while file
          filename = file.filename

          if subarchive_found?(filename, subarchive)
            file_path = File.join(Dir.mktmpdir, filename)
            decompressor.extract(file, file_path)

            return file_path
          end

          file = file.next
        end
      end

      def subarchive_found?(filename, subarchive)
        return subarchive == filename if subarchive

        filename.include?("cab") || filename.include?("msi")
      end
    end
  end
end
