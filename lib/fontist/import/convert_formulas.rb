require_relative "formula_serializer"

module Fontist
  module Import
    class ConvertFormulas
      def call
        find_formulas.each do |formula|
          convert_to_yaml(formula)
        end
      end

      private

      def find_formulas
        require_formulas_files
        formulas_instances
      end

      def require_formulas_files
        path = Fontist.lib_path.join("fontist", "converted_formulas")
        Dir[path.join("**/*.rb").to_s].sort.each do |file|
          require file
        end
      end

      def formulas_instances
        classes = Formulas.constants.select do |constant|
          Formulas.const_get(constant).is_a?(Class)
        end

        classes.map do |constant|
          Object.const_get("Fontist::Formulas::#{constant}").instance
        end
      end

      def convert_to_yaml(formula)
        hash = formula_hash(formula)
        write_yaml(formula, hash)
      end

      def formula_hash(formula)
        code = File.read(formula_path(formula))
        FormulaSerializer.new(formula, code).call
      end

      def formula_path(formula)
        formula.method(:extract).source_location.first
      end

      def write_yaml(formula, hash)
        File.write(yaml_formula_path(formula), YAML.dump(stringify_keys(hash)))
      end

      def yaml_formula_path(formula)
        name = formula_path(formula).match(/formulas\/(.*)_fonts?.rb/)[1]

        Fontist.formulas_path.join("#{name}.yml")
      end

      def stringify_keys(hash)
        JSON.parse(hash.to_json)
      end
    end
  end
end
