require_relative "helpers/hash_helper"

module Fontist
  module Import
    class RebuildIndex
      def initialize
        @index = {}
      end

      def call
        files.each do |file|
          parse_file(file)
        end

        save_index
      end

      private

      def files
        Dir[Fontist.formulas_path.join("**/*.yml").to_s].sort
      end

      def parse_file(file)
        hash = YAML.load_file(file)
        formula = Helpers::HashHelper.parse_to_object(hash)
        relative_path = file.delete_prefix(Fontist.formulas_path.to_s + "/")
        parse_formula(formula, relative_path)
      end

      def parse_formula(formula, path)
        parse_collections(formula.font_collections, path)
        parse_fonts(formula.fonts, path)
      end

      def parse_collections(collections, path)
        return unless collections

        collections.each do |collection|
          parse_fonts(collection.fonts, path)
        end
      end

      def parse_fonts(fonts, path)
        return unless fonts

        fonts.each do |font|
          parse_font(font, path)
        end
      end

      def parse_font(font, path)
        font.styles.each do |style|
          parse_style(style, font, path)
        end
      end

      def parse_style(style, font, path)
        fill_index(font.name, style.type, path)
      end

      def fill_index(font_name, style_name, formula_path)
        @index[font_name] ||= {}
        @index[font_name][style_name] ||= []
        @index[font_name][style_name] << formula_path unless @index[font_name][style_name].include?(formula_path)
      end

      def save_index
        File.write(Fontist.formula_index_path, YAML.dump(@index))
      end
    end
  end
end
