require "lutaml/model"
require_relative "indexes/filename_index"
require_relative "indexes/font_index"
require_relative "indexes/default_family_font_index"
require_relative "indexes/preferred_family_font_index"

module Fontist
  class IndexEntry < Lutaml::Model::Serializable
    attribute :path, :string
    attribute :full_name, :string
    attribute :family_name, :string
    attribute :style, :string
    attribute :type, :string
    attribute :source_font, :string

    key_value do
      map "path", to: :path
      map "full_name", to: :full_name
      map "family_name", to: :family_name
      map "style", to: :style
      map "type", to: :type
      map "source_font", to: :source_font
    end
  end

  class Index < Lutaml::Model::Collection
    instances :entries, IndexEntry

    key_value do
      map_instances to: :entries
    end

    def self.from_file(path)
      return new unless File.exist?(path)

      content = File.read(path)
      from_yaml(content)
    end

    def to_file(path)
      File.write(path, to_yaml)
    end

    def self.rebuild
      Fontist::Indexes::DefaultFamilyFontIndex.rebuild.to_file
      Fontist::Indexes::PreferredFamilyFontIndex.rebuild.to_file
      Fontist::Indexes::FilenameIndex.rebuild.to_file

      reset_cache
    end

    # TODO: Uncomment all lines when each fixed
    def self.reset_cache
      # Fontist::Indexes::DefaultFamilyFontIndex.reset_cache
      # Fontist::Indexes::PreferredFamilyFontIndex.reset_cache
      # Fontist::Indexes::FilenameIndex.reset_cache
    end

  end
end
