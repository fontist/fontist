require "lutaml/model"

module Fontist
  # FontModel - uses FontStyle with v5 format metadata
  class FontModel < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :styles, FontStyle, collection: true

    key_value do
      map "name", to: :name
      map "styles", to: :styles
    end
  end
end
