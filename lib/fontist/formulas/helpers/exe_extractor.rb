module Fontist
  module Formulas
    module Helpers
      module ExeExtractor
        def cab_extract(exe_file, download: true,  font_ext: /.tt|.ttc/i)
          exe_file = download_file(exe_file).path if download
          cab_file = decompressor.search(exe_file)
          cabbed_fonts = grep_fonts(cab_file.files, font_ext) || []
          fonts_paths = extract_cabbed_fonts_to_assets(cabbed_fonts)

          yield(fonts_paths) if block_given?
        end

        private

        def decompressor
          @decompressor ||= (
            require "libmspack"
            LibMsPack::CabDecompressor.new
          )
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
      end
    end
  end
end
