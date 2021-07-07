require_relative "base_index"

module Fontist
  module Indexes
    class PreferredFamilyFontIndex < BaseIndex
      def self.path
        Fontist.formula_preferred_family_index_path
      end

      def add_formula(formula)
        formula.fonts.each do |font|
          font.styles.each do |style|
            font_name = style.preferred_family_name || font.name
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
