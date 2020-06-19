module Fontist
  class Formula
    def initialize(font_name)
      @font_name = font_name
    end

    def self.find(font_name)
      new(font_name).find
    end

    def self.find_fonts(name)
      new(name).find_fonts
    end

    def find
      formulas = [find_formula].flatten
      formulas.empty? ? nil : formulas
    end

    def find_fonts
      formulas = [find_formula].flatten
      match_fonts_by_name(formulas) unless formulas.empty?
    end

    private

    attr_reader :font_name

    def find_formula
      find_by_font_name || find_by_font || []
    end

    def formulas
      @formulas ||= Fontist::Formulas.all.to_h
    end

    def match_fonts_by_name(formulas)
      matched_fonts = formulas.map do |formula|
        formula.fonts.select do |font|
          font.name.downcase == font_name.downcase
        end
      end

      matched_fonts.empty? ? nil : matched_fonts.flatten
    end

    def find_by_font_name
      matched_formulas = formulas.select do |key, value|
        !value.fonts.map(&:name).grep(/#{font_name}/i).empty?
      end

      matched_formulas.empty? ? nil : matched_formulas.values
    end

    # Note
    #
    # These interface recursively look into every single font styles,
    # so ideally try to avoid using it when possible, and that's why
    # we've added it as last option in formula finder.
    #
    def find_by_font
      matched_formulas = formulas.select do |key, value|
        match_in_font_styles?(value[:fonts])
      end

      matched_formulas.empty? ? nil : matched_formulas.values
    end

    def match_in_font_styles?(fonts)
      styles = fonts.select do |font|
        !font.styles.map(&:font).grep(/#{font_name}/i).empty?
      end

      styles.empty? ? false : true
    end
  end
end
