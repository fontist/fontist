require_relative "base_index"

module Fontist
  module Indexes
    class FilenameIndex < BaseIndex
      def self.path
        Fontist.formula_filename_index_path
      end

      def add_formula(formula)
        formula.fonts.each do |font|
          font.styles.each do |style|
            add_index_formula(style.font, formula.to_index_formula)
          end
        end
      end
    end
  end
end
