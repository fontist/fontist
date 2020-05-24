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

    def find_system_font
      Fontist::SystemFont.find(font_name)
    end

    def font_formulas
      Fontist::FormulaFinder.find(font_name)
    end

    def font_installer(name)
      Object.const_get(name)
    end

    def download_font
      if font_formulas
        font_formulas.map do |formula|
          font_installer(formula[:installer]).fetch_font(
            font_name,
            confirmation: confirmation,
          )
        end.flatten
      end
    end
  end
end
