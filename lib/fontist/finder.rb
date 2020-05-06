module Fontist
  class Finder
    def initialize(name)
      @name = name
    end

    def self.find(name)
      new(name).find
    end

    def find
      find_system_font || downloadable_font || raise_invalid_error
    end

    private

    attr_reader :name

    def find_system_font
      Fontist::SystemFont.find(name)
    end

    def remote_source
      Fontist::Source.formulas.to_h.select do |key, value|
        !value.fonts.grep(/#{name}/i).empty?
      end
    end

    def downloadable_font
      unless remote_source.empty?
        raise(
          Fontist::Errors::MissingFontError,
          "Fonts are missing, please run" \
          "Fontist::Installer.download(name, confirmation: 'yes') to " \
          "download these fonts"
        )
      end
    end

    def raise_invalid_error
      raise(
        Fontist::Errors::NonSupportedFontError,
        "Could not find the #{name} font in any of the supported downlodable"
      )
    end
  end
end
