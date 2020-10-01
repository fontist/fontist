module Fontist
  module Utils
    module ExeExtractor
      def cab_extract(exe_file, download: true,
                      font_ext: /.ttf|.otf|.ttc/i,
                      files: nil)
        download = @downloaded === true ? false : download

        exe_file = download_file(exe_file).path if download
        cab_file = decompressor.search(exe_file)
        cabbed_fonts = grep_fonts(cab_file.files, font_ext, files) || []
        fonts_paths = extract_cabbed_fonts_to_assets(cabbed_fonts)

        block_given? ? yield(fonts_paths) : fonts_paths
      end

      def exe_extract(source, files: nil)
        cab_file = decompressor.search(download_file(source).path)
        fonts_paths = build_cab_file_hash(cab_file.files)
        block_given? ? yield(fonts_paths) : fonts_paths
      end

      private

      def decompressor
        @decompressor ||= (
          require "libmspack"
          LibMsPack::CabDecompressor.new
        )
      end

      def grep_fonts(file, font_ext, content_files)
        Array.new.tap do |fonts|
          while file
            if file.filename.match(font_ext)
              fonts.push(file) unless content_files && !content_files.include?(file.filename)
            end

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

      def build_cab_file_hash(file)
        Hash.new.tap do |cab_files|
          while file
            filename = file.filename
            if filename.include?("cab")
              file_path = temp_dir.join(filename).to_s

              decompressor.extract(file, file_path)
              cab_files[filename.to_s] = file_path
            end

            file = file.next
          end
        end
      end

      def temp_dir
        @temp_dir ||= raise(
          NotImplementedError.new("You must implement this method"),
        )
      end
    end
  end
end
