
module Fontist
  module Indexes
    class FormulaKeyToPath < Lutaml::Model::Serializable
      attribute :key, :string
      attribute :formula_path, :string, collection: true

      key_value do
        map "key", to: :key
        map "formula_path", to: :formula_path
      end

      def to_full
        Formula.from_file(full_path)
      end

      private

      def full_path
        Fontist.formulas_path.join(formula_path.first).to_s
      end
    end
  end
end
