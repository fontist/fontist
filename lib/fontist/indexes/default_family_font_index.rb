require_relative "base_index"

module Fontist
  module Indexes
    class DefaultFamilyFontIndex < BaseIndex
      def self.path
        Fontist.formula_index_path
      end

      def add_formula(formula)
        formula.fonts.each do |font|
          font.styles.each do |style|
            font_name = style.default_family_name || font.name
            add_index_formula(font_name, formula.to_index_formula)
          end
        end
      end

      def normalize_key(key)
        key.downcase
      end
    end
  end
end
