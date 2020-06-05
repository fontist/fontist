require "fontist/formulas/helpers/dsl"
require "fontist/formulas/cleartype_fonts"
require "fontist/formulas/open_sans_fonts"
require "fontist/formulas/euphemia_font"

module Fontist
  module Formulas
    def self.all
      register_formulas
      registry.formulas
    end

    private

    def self.registry
      @registry = Fontist::Registry
    end

    def self.register_formulas
      registry.register(Fontist::Formulas::ClearTypeFonts, :cleartype)
      registry.register(Fontist::Formulas::OpenSansFonts, :open_sans_fonts)
      registry.register(Fontist::Formulas::EuphemiaFont, :euphemia_font)
    end
  end
end
