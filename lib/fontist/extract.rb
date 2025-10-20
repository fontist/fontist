require "lutaml/model"

module Fontist
  class ExtractOptions < Lutaml::Model::Serializable
    attribute :file, :string
    attribute :fonts_sub_dir, :string

    key_value do
      map "file", to: :file
      map "fonts_sub_dir", to: :fonts_sub_dir
    end
  end

  class Extract < Lutaml::Model::Serializable
    attribute :format, :string
    attribute :file, :string
    attribute :options, ExtractOptions, collection: true

    key_value do
      map "format", to: :format
      map "file", to: :file
      map "options", to: :options
    end
  end
end
