require "lutaml/model"
require_relative "font_model"

module Fontist
  class FontCollection < Lutaml::Model::Serializable
    attribute :filename, :string
    attribute :source_filename, :string
    attribute :fonts, FontModel, collection: true

    key_value do
      map "filename", to: :filename
      map "source_filename", to: :source_filename
      map "fonts", to: :fonts
    end
  end
end
