require "fontist/downloader"

module Fontist
  class MsVistaFont
    def initialize(font_name, fonts_path: nil)
      @font_name = font_name
      @fonts_path = fonts_path ||  Fontist.fonts_path
    end

    def self.fetch_font(font_name, fonts_path: nil)
      new(font_name, fonts_path: fonts_path).fetch
    end

    def fetch
      fonts = extract_ppviewer_fonts
      fonts.grep(/#{font_name}/)
    end

    private

    attr_reader :fonts_path, :font_name

    def decompressor
      @decompressor ||= LibMsPack::CabDecompressor.new
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

    def cabbed_fonts
      exe_file = decompressor.search(download_exe_file.path)
      decompressor.extract(exe_file.files.next, ppviewer_cab)
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
      @source ||= Fontist::Source.all.remote.msvista
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
