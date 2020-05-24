require "fontist/formulas/base"
require "fontist/formulas/ms_vista"
require "fontist/formulas/ms_system"
require "fontist/formulas/source_font"
require "fontist/formulas/courier_font"

require "fontist/formulas/helpers/dsl"
require "fontist/formulas/cleartype_fonts"

require "fontist/registry"

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
    end
  end
end
