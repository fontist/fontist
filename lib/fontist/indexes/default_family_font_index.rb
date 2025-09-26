require "lutaml/model"
require_relative "index_mixin"
require_relative "formula_key_to_path"

module Fontist
  module Indexes
    # YAML file structure:
    # ---
    # adobe arabic:
    # - adobe_reader_19.yml
    # myriad pro:
    # - adobe_reader_20.yml
    # akabara-cinderella:
    # - akabara-cinderella.yml
    # andale mono:
    # - andale.yml
    # - macos/andale_mono.yml
    # - opensuse_webcore_fonts.yml
    # - pclinuxos_webcore_fonts.yml
    class DefaultFamilyFontIndex < Lutaml::Model::Collection
      include IndexMixin
      instances :entries, FormulaKeyToPath

      key_value do
        map_key to_instance: :key
        map_value as_attribute: :formula_path
        map_instances to: :entries
      end

      def self.path
        Fontist.formula_index_path
      end

      def index_key_for_style(style)
        style.default_family_name || style.family_name
      end

      def normalize_key(key)
        key.downcase
      end
    end
  end
end
