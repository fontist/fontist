# frozen_string_literal: true

require "lutaml/model"

module Fontist
  module Import
    module Google
      module Models
        # Model for individual font file metadata
        class FontFileMetadata < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :style, :string
          attribute :weight, :integer
          attribute :filename, :string
          attribute :post_script_name, :string
          attribute :full_name, :string
          attribute :copyright, :string

          key_value do
            map "name", to: :name
            map "style", to: :style
            map "weight", to: :weight
            map "filename", to: :filename
            map "post_script_name", to: :post_script_name
            map "full_name", to: :full_name
            map "copyright", to: :copyright
          end
        end
      end
    end
  end
end