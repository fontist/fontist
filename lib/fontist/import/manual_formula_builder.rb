require_relative "formula_builder"

module Fontist
  module Import
    class ManualFormulaBuilder < FormulaBuilder
      attr_accessor :description,
                    :platforms,
                    :instructions

      private

      def formula_attributes
        @formula_attributes ||= super.dup.tap do |attrs|
          attrs.delete(:resources)
          attrs.delete(:open_license)
          attrs.delete(:license_url)
          attrs.delete(:copyright)

          attrs.insert(attrs.index(:homepage) + 1, :platforms, :instructions)
        end
      end
    end
  end
end
