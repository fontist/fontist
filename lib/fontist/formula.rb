module Fontist
  class Formula
    def initialize(options = {})
      @font_name = options.fetch(:font_name, nil)
      @style_name = options.fetch(:style_name, nil)

      check_and_register_font_formulas
    end

    def self.all
      new.all
    end

    def self.find(font_name)
      new(font_name: font_name).find
    end

    def self.find_fonts(name)
      new(font_name: name).find_fonts
    end

    def self.find_styles(font, style)
      new(font_name: font, style_name: style).find_styles
    end

    def all
      @all ||= Fontist::Registry.instance.formulas
    end

    def find
      [find_formula].flatten.first
    end

    def find_fonts
      formulas = [find_formula].flatten
      fonts = take_fonts(formulas)
      fonts.empty? ? nil : fonts
    end

    def find_styles
      formulas.values.flat_map do |formula|
        formula.fonts.flat_map do |f|
          f.styles.select do |s|
            f.name.casecmp?(font_name) && s.type.casecmp?(style_name)
          end
        end
      end
    end

    private

    attr_reader :font_name, :style_name

    def find_formula
      find_by_key || find_by_font_name || find_by_font || []
    end

    def formulas
      @formulas ||= all.to_h
    end

    def take_fonts(formulas)
      formulas.map(&:fonts).flatten
    end

    def find_by_key
      matched_formulas = formulas.select do |key, _value|
        key.to_s.casecmp?(font_name)
      end

      matched_formulas.empty? ? nil : matched_formulas.values
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

    def check_and_register_font_formulas
      $check_and_register_font_formulas ||= Fontist::Formulas.register_formulas
    end
  end
end
