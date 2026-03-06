require "lutaml/model"

module Fontist
  # Resource - v5 resource with format metadata for multi-format support
  class Resource < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :source, :string
    attribute :urls, :string, collection: true
    attribute :sha256, :string, collection: true
    attribute :file_size, :integer
    attribute :family, :string
    attribute :files, :string, collection: true

    # v5 format metadata
    attribute :format, :string # ttf, otf, woff2, ttc, otc
    attribute :variable_axes, :string, collection: true # [wght], [ital,wght], etc.

    # Web-enabled format support (v5 feature #3)
    attribute :css_url, :string # Google Fonts CSS URL for web embedding

    key_value do
      map "name", to: :name
      map "source", to: :source
      map "urls", to: :urls
      map "sha256", to: :sha256
      map "file_size", to: :file_size
      map "family", to: :family
      map "files", to: :files
      map "format", to: :format
      map "variable_axes", to: :variable_axes
      map "css_url", to: :css_url
    end

    def empty?
      Array(urls).empty? && Array(files).empty?
    end

    def variable_font?
      variable_axes && !variable_axes.empty?
    end

    def static_font?
      !variable_font?
    end

    def axes_tags
      Array(variable_axes).map(&:to_s)
    end

    def has_axis?(tag)
      axes_tags.include?(tag.to_s)
    end

    def collection_file?
      %w[ttc otc].include?(format&.to_s)
    end
  end
end
