require "fontist/utils"
require "fontist/font_formula"
require "fontist/formula_template"

module Fontist
  module Formulas
    REQUIREMENTS = { git: Fontist::Utils::GitRequirement.new }.freeze

    def self.register_formulas
      fetch_formulas
      load_formulas
      update_registry
    end

    def self.fetch_formulas
      if Dir.exist?(Fontist.formulas_repo_path)
        REQUIREMENTS[:git].pull(Fontist.formulas_repo_path)
      else
        REQUIREMENTS[:git].clone(Fontist.formulas_repo_url,
                                 Fontist.formulas_repo_path)
      end
    end

    def self.load_formulas
      Dir[Fontist.formulas_path.join("**/*.yml").to_s].sort.each do |file|
        create_formula_class(file)
      end
    end

    def self.create_formula_class(file)
      formula = parse_to_object(YAML.load_file(file))
      return if Formulas.const_defined?("#{formula.name}Font")

      klass = FormulaTemplate.create_formula_class(formula)
      Formulas.const_set("#{formula.name}Font", klass)
    end

    def self.parse_to_object(hash)
      JSON.parse(hash.to_json, object_class: OpenStruct)
    end

    def self.update_registry
      Formulas.constants.select do |constant|
        if Formulas.const_get(constant).is_a?(Class)
          klass = "Fontist::Formulas::#{constant}"
          Fontist::Registry.register(Object.const_get(klass))
        end
      end
    end
  end
end
