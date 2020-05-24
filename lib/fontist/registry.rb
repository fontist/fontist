module Fontist
  class Registry
    include Singleton

    def initialize
      @formulas ||= {}
    end

    def formulas
      parse_to_object(@formulas)
    end

    def self.formulas
      instance.formulas
    end

    def self.register(formula, key = nil)
      key ||= formula.to_s
      instance.register(formula, key)
    end

    def register(formula, key)
      @formulas[key] = build_formula_data(formula)
    end

    private

    def build_formula_data(formula)
      {
        installer: formula,
        fonts: formula.instance.fonts,
        homepage: formula.instance.homepage ,
        description: formula.instance.description,
      }
    end

    def parse_to_object(data)
      JSON.parse(data.to_json, object_class: OpenStruct)
    end
  end
end
