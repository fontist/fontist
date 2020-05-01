require "fontist/downloader"

module Fontist
  class MsVistaFont
    def initialize(font_name, confirmation:, fonts_path: nil, **options)
      @font_name = font_name
      @confirmation = confirmation || "no"
      @fonts_path = fonts_path ||  Fontist.fonts_path
      @force_download = options.fetch(:force_download, false)

      unless source.agreement === confirmation
        raise(Fontist::Errors::LicensingError)
      end
    end

    def self.fetch_font(font_name, confirmation:, **options)
      new(font_name, options.merge(confirmation: confirmation)).fetch
    end

    def fetch
      fonts = extract_ppviewer_fonts
      paths = fonts.grep(/#{font_name}/i)
      paths.empty? ? nil : paths
    end

    private

    attr_reader :font_name, :fonts_path, :force_download

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
