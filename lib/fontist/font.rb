module Fontist
  class Font
    def initialize(name, options = {})
      @name = name
      @confirmation = options.fetch(:confirmation, "no")
    end

    def self.find(name)
      new(name).find
    end

    def self.install(name, confirmation: "no")
      new(name, confirmation: confirmation).install
    end

    def find
      find_system_font || downloadable_font || raise(
        Fontist::Errors::NonSupportedFontError
      )
    end

    def install
      find_system_font || download_font || raise(
        Fontist::Errors::NonSupportedFontError
      )
    end

    private

    attr_reader :name, :confirmation

    def find_system_font
      Fontist::SystemFont.find(name)
    end

    def font_installer(formula)
      Object.const_get(formula.installer)
    end

    def formulas
      @formulas ||= Fontist::FormulaFinder.find(name)
    end

    def downloadable_font
      unless formulas.nil?
        raise(
          Fontist::Errors::MissingFontError,
          "Fonts are missing, please run " \
          "Fontist::Font.install('#{name}', confirmation: 'yes') to " \
          "download the font"
        )
      end
    end

    def download_font
      unless formulas.nil?
        formulas.map do |formula|
          font_installer(formula).fetch_font(name, confirmation: confirmation)
        end.flatten
      end
    end
  end
end
