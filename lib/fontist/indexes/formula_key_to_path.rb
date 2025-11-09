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
        formula_path.map { |p| Formula.from_file(full_path(p)) }
      end

      def name
        formula_path.map { |p| normalized(p) }
      end

      def normalized(path)
        return "" unless path

        escaped = Regexp.escape("#{Fontist.formulas_path}/")
        path.sub(Regexp.new("^#{escaped}"), "").sub(/\.yml$/, "").to_s
      end

      private

      def full_path(path)
        Fontist.formulas_path.join(path).to_s
      end
    end
  end
end
