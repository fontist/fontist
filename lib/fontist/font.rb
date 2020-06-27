module Fontist
  class Font
    def initialize(options = {})
      @name = options.fetch(:name, nil)
      @confirmation = options.fetch(:confirmation, "no")
    end

    def self.all
      new.all
    end

    def self.find(name)
      new(name: name).find
    end

    def self.install(name, confirmation: "no")
      new(name: name, confirmation: confirmation).install
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

    def all
      Fontist::Formula.all.to_h.map { |_name, formula| formula.fonts }.flatten
    end

    private

    attr_reader :name, :confirmation

    def find_system_font
      Fontist::SystemFont.find(name)
    end

    def font_installer(formula)
      Object.const_get(formula.installer)
    end

    def formula
      @formula ||= Fontist::Formula.find(name)
    end

    def downloadable_font
      if formula
        raise(
          Fontist::Errors::MissingFontError,
          "Fonts are missing, please run " \
          "Fontist::Font.install('#{name}', confirmation: 'yes') to " \
          "download the font"
        )
      end
    end

    def download_font
      if formula
        font_installer(formula).fetch_font(name, confirmation: confirmation)
      end
    end
  end
end
