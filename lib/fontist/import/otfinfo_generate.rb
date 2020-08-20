require "erb"
require_relative "template_helper"
require_relative "otf_parser"
require_relative "otf_style"

module Fontist
  module Import
    class OtfinfoGenerate
      TEMPLATE_PATH = File.expand_path("otfinfo/template.erb", __dir__)

      def initialize(font)
        @font = font
      end

      def call
        paths = font_paths(@font)
        puts paths
        styles = generate_styles(paths)
        puts render(styles)
      end

      private

      def font_paths(font)
        formula = Fontist::Formula.find(font)
        font_formula = Object.const_get(formula.installer)
        font_formula.fetch_font(nil, confirmation: "yes")
      end

      def generate_styles(paths)
        paths.map do |path|
          info = OtfParser.new(path).call
          OtfStyle.new(info, path).call
        end
      end

      def render(styles)
        template = File.read(TEMPLATE_PATH)
        renderer = ERB.new(template, trim_mode: "-")
        renderer.result(Fontist::Import::TemplateHelper.bind(styles))
      end
    end
  end
end
