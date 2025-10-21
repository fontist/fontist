require "lutaml/model"
require_relative "font_style"

module Fontist
  class FontModel < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :styles, FontStyle, collection: true

    key_value do
      map "name", to: :name
      map "styles", to: :styles
    end

  end
end
