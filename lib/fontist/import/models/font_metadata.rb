require "lutaml/model"

module Fontist
  module Import
    module Models
      class FontMetadata < Lutaml::Model::Serializable
        attribute :family_name, :string
        attribute :subfamily_name, :string
        attribute :full_name, :string
        attribute :postscript_name, :string
        attribute :preferred_family_name, :string
        attribute :preferred_subfamily_name, :string
        attribute :version, :string
        attribute :copyright, :string
        attribute :description, :string
        attribute :vendor_url, :string
        attribute :license_url, :string
        attribute :font_format, :string
        attribute :is_variable, :boolean

        json do
          map "family_name", to: :family_name
          map "subfamily_name", to: :subfamily_name
          map "full_name", to: :full_name
          map "postscript_name", to: :postscript_name
          map "preferred_family_name", to: :preferred_family_name
          map "preferred_subfamily_name", to: :preferred_subfamily_name
          map "version", to: :version
          map "copyright", to: :copyright
          map "description", to: :description
          map "vendor_url", to: :vendor_url
          map "license_url", to: :license_url
          map "font_format", to: :font_format
          map "is_variable", to: :is_variable
        end
      end
    end
  end
end
