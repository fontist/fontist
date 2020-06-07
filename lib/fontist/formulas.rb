require "fontist/formulas/helpers/dsl"
require "fontist/formulas/cleartype_fonts"
require "fontist/formulas/open_sans_fonts"
require "fontist/formulas/euphemia_font"
require "fontist/formulas/montserrat_font"
require "fontist/formulas/overpass_font"
require "fontist/formulas/source_fonts"
require "fontist/formulas/stix_fonts"

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
      registry.register(Fontist::Formulas::MontserratFont, :montserrat_font)
      registry.register(Fontist::Formulas::OverpassFont, :overpass_font)
      registry.register(Fontist::Formulas::SourceFonts, :source_fonts)
      registry.register(Fontist::Formulas::StixFont, :stix_fonts)
    end
  end
end
