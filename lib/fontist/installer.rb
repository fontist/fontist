module Fontist
  class Installer
    def initialize(font_name:, confirmation:, **options)
      @font_name = font_name
      @confirmation = confirmation.downcase
      @options = options
    end

    def download
      find_system_font || download_font || raise(
        Fontist::Errors::NonSupportedFontError
      )
    end

    def self.download(font_name, confirmation:)
      new(font_name: font_name, confirmation: confirmation).download
    end

    private

    attr_reader :font_name, :confirmation, :options

    def downloaders
      {
        msvista: Fontist::Formulas::MsVista,
        ms_system: Fontist::Formulas::MsSystem,
        source_front: Fontist::Formulas::SourceFont,
      }
    end

    def find_system_font
      Fontist::SystemFont.find(font_name)
    end

    def download_font
      if !font_sources.empty?
        downloader = downloaders[font_sources.first]
        downloader.fetch_font(font_name, confirmation: confirmation)
      end
    end

    def font_sources
      @font_sources ||= Fontist::Source.formulas.to_h.select do |key, value|
        !value.fonts.grep(/#{font_name}/i).empty?
      end.keys
    end
  end
end
