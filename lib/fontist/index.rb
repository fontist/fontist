require_relative "index_formula"

module Fontist
  class Index
    def self.from_yaml
      unless File.exist?(Fontist.formula_index_path)
        raise Errors::FormulaIndexNotFoundError.new("Please fetch index with `fontist update`.")
      end

      data = YAML.load_file(Fontist.formula_index_path)
      new(data)
    end

    def self.rebuild
      index = new
      index.build
      index.to_yaml
    end

    def initialize(data = {})
      @index = {}

      data.each_pair do |font, paths|
        paths.each do |path|
          add_index_formula(font, IndexFormula.new(path))
        end
      end
    end

    def build
      Formula.all.each do |formula|
        add_formula(formula)
      end
    end

    def add_formula(formula)
      formula.fonts.each do |font|
        add_index_formula(font.name, formula.to_index_formula)
      end
    end

    def add_index_formula(font_raw, index_formula)
      font = normalize_font(font_raw)
      @index[font] ||= []
      @index[font] << index_formula unless @index[font].include?(index_formula)
    end

    def load_formulas(font)
      index_formulas(font).map(&:to_full)
    end

    def to_yaml
      File.write(Fontist.formula_index_path, YAML.dump(to_h))
    end

    def to_h
      @index.map do |font, index_formulas|
        [font, index_formulas.map(&:to_s)]
      end.to_h
    end

    private

    def index_formulas(font)
      @index[normalize_font(font)] || []
    end

    def normalize_font(font)
      font.downcase
    end
  end
end
