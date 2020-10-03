module Fontist
  class FontistFont
    def initialize(font:)
      @font = font
    end

    def self.find(font)
      new(font: font).find
    end

    def find
      font_names = map_name_to_valid_font_names
      return unless font_names

      paths = font_paths.grep(/#{font_names.join("|")}/i)
      paths.empty? ? nil : paths
    end

    private

    attr_reader :font

    def map_name_to_valid_font_names
      fonts = Formula.find_fonts(font)
      return unless fonts

      fonts.map { |font| font.styles.map(&:font) }.flatten
    end

    def font_paths
      Dir.glob(Fontist.fonts_path.join("**"))
    end
  end
end
