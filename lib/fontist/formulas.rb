require "fontist/formulas/helpers/dsl"
require "fontist/formulas/cleartype_fonts"
require "fontist/formulas/open_sans_fonts"
require "fontist/formulas/euphemia_font"
require "fontist/formulas/montserrat_font"
require "fontist/formulas/overpass_font"
require "fontist/formulas/source_fonts"
require "fontist/formulas/stix_fonts"
require "fontist/formulas/tahoma_font"
require "fontist/formulas/ms_truetype_fonts"
require "fontist/formulas/arial_black_font"
require "fontist/formulas/andale_font"
require "fontist/formulas/comic_font"
require "fontist/formulas/courier_font"

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
      registry.register(Fontist::Formulas::TahomaFont, :tahoma_font)
      registry.register(Fontist::Formulas::MsTruetypeFonts, :ms_truetype_fonts)
      registry.register(Fontist::Formulas::ArialBlackFont, :arial_black_font)
      registry.register(Fontist::Formulas::AndaleFont, :andale_font)
      registry.register(Fontist::Formulas::ComicFont, :comic_font)
      registry.register(Fontist::Formulas::CourierFont, :courier_font)
    end
  end
end
