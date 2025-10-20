require "lutaml/model"

module Fontist
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
    end
  end
end
