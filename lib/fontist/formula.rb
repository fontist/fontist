require "fontist/index"

module Fontist
  class Formula
    def initialize(options = {})
      @font_name = options.fetch(:font_name, nil)
      @style_name = options.fetch(:style_name, nil)
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
      @all ||= Index.load_all
    end

    def find
      Index.load_formulas(font_name).first
    end

    def find_fonts
      formulas = Index.load_formulas(font_name)

      formulas.map do |formula|
        formula.fonts.select do |f|
          f.name.casecmp?(font_name)
        end
      end.flatten
    end

    def find_styles
      formulas = Index.load_formulas(font_name, style_name)

      formulas.map do |formula|
        formula.fonts.map do |f|
          f.styles.select do |s|
            f.name.casecmp?(font_name) && s.type.casecmp?(style_name)
          end
        end
      end.flatten
    end

    private

    attr_reader :font_name, :style_name
  end
end
