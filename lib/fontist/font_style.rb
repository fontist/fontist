require "lutaml/model"

module Fontist
  # FontStyle - v5 font style with format metadata for multi-format support
  class FontStyle < Lutaml::Model::Serializable
    attribute :family_name, :string
    attribute :type, :string
    attribute :full_name, :string
    attribute :post_script_name, :string
    attribute :version, :string
    attribute :description, :string
    attribute :copyright, :string
    attribute :font, :string
    attribute :source_font, :string
    attribute :preferred_family_name, :string
    attribute :preferred_type, :string
    attribute :default_family_name, :string
    attribute :default_type, :string
    attribute :override, :string

    # v5 format metadata
    attribute :formats, :string, collection: true # ["ttf", "woff2"]
    attribute :variable_font, :boolean # true/false
    attribute :variable_axes, :string, collection: true # ["wght", "wdth"]
    attribute :source_resource, :string

    key_value do
      map "family_name", to: :family_name
      map "type", to: :type
      map "preferred_family_name", to: :preferred_family_name
      map "preferred_type", to: :preferred_type
      map "full_name", to: :full_name
      map "post_script_name", to: :post_script_name
      map "version", to: :version
      map "description", to: :description
      map "copyright", to: :copyright
      map "font", to: :font
      map "source_font", to: :source_font
      map "default_family_name", to: :default_family_name
      map "default_type", to: :default_type
      map "override", to: :override
      map "formats", to: :formats
      map "variable_font", to: :variable_font
      map "variable_axes", to: :variable_axes
      map "source_resource", to: :source_resource
    end

    # Helper to check if this is a variable font
    # Returns false if not set, true only if explicitly set to true
    def variable_font?
      variable_font == true
    end
  end
end
