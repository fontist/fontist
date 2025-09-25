require "lutaml/model"
require_relative "index_mixin"
require_relative "formula_key_to_path"

module Fontist
  module Indexes
    # YAML file structure:
    # ---
    # AdobeArabic_Bold.otf:
    # - adobe_reader_19.yml
    # AdobeArabic_BoldItalic.otf:
    # - adobe_reader_19.yml
    # AdobeArabic_Italic.otf:
    # - adobe_reader_19.yml
    # AdobeArabic_Regular.otf:
    # - adobe_reader_19.yml
    # adobedevanagari_bold.otf:
    # - adobe_reader_19.yml
    class FilenameIndex < Lutaml::Model::Collection
      include IndexMixin
      instances :entries, FormulaKeyToPath

      key_value do
        map_key to_instance: :key
        map_value as_attribute: :formula_path
        map_instances to: :entries
      end

      def self.path
        Fontist.formula_filename_index_path
      end

      ## Fonts
      # fonts:
      # - name: Adobe Pi Std
      #   styles:
      #   - family_name: Adobe Pi Std
      #     type: Regular

      ## Font collections
      # font_collections:
      # - filename: AdelleSans.ttc
      #   fonts:
      #   - name: Adelle Sans Devanagari
      #     styles:

      def add_index_formula(style, formula_path)
        # e.g.     font: Lato-Bold.ttf
        key = normalize_key(style.font)

        return if index_formula(key)

        formula_path = Array(formula_path)
        paths = formula_path.map { |p| relative_formula_path(p) }

        entries << FormulaKeyToPath.new(
          key: key,
          formula_path: paths,
        )
      end

      def normalize_key(key)
        key
      end
    end
  end
end
