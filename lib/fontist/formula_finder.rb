module Fontist
  class FormulaFinder
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
      formulas = find_formula
      build_formulas_array(formulas)
    end

    def find_fonts
      matched_fonts = find_formula.map do |key, _value|
        formulas[key].fonts.select do |font|
          font.name == font_name
        end
      end

      matched_fonts.empty? ? nil : matched_fonts.flatten
    end

    private

    attr_reader :font_name

    def build_formulas_array(formulas)
      unless formulas.empty?
        Array.new.tap do |formula_array|
          formulas.each do |key|
            formula_array.push(
              key: key.to_s,
              installer: formula_installers[key]
            )
          end
        end
      end
    end

    def find_formula
      find_by_font_name || find_by_font || []
    end

    def formulas
      @formulas ||=  Fontist::Source.formulas.to_h
    end

    def formula_installers
      {
        msvista: Fontist::Formulas::MsVista,
        ms_system: Fontist::Formulas::MsSystem,
        courier: Fontist::Formulas::CourierFont,
        source_front: Fontist::Formulas::SourceFont,
      }
    end

    def find_by_font_name
      formula_names = formulas.select do |key, value|
        !value.fonts.map(&:name).grep(/#{font_name}/i).empty?
      end.keys

      formula_names.empty? ? nil : formula_names
    end

    # Note
    #
    # These interface recursively look into every single font styles,
    # so ideally try to avoid using it when possible, and that's why
    # we've added it as last option in formula finder.
    #
    def find_by_font
      formula_names = formulas.select do |key, value|
        match_in_font_styles?(value.fonts)
      end.keys

      formula_names.empty? ? nil : formula_names
    end

    def match_in_font_styles?(fonts)
      styles = fonts.select do |font|
        !font.styles.map(&:font).grep(/#{font_name}/i).empty?
      end

      styles.empty? ? false : true
    end
  end
end
