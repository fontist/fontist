require_relative "base_index"

module Fontist
  module Indexes
    class FontIndex < BaseIndex
      def self.path
        Fontist.formula_index_path
      end

      def add_formula(formula)
        formula.fonts.each do |font|
          add_index_formula(font.name, formula.to_index_formula)
        end
      end

      def normalize_key(key)
        key.downcase
      end
    end
  end
end
