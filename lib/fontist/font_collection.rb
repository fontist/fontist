require "lutaml/model"

module Fontist
  # FontCollection - uses FontModel with v5 format metadata
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
