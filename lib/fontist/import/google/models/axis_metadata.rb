# frozen_string_literal: true

require "lutaml/model"

module Fontist
  module Import
    module Google
      module Models
        # Model for variable font axis metadata
        class AxisMetadata < Lutaml::Model::Serializable
          attribute :tag, :string
          attribute :min_value, :float
          attribute :max_value, :float
          attribute :default_value, :float

          key_value do
            map "tag", to: :tag
            map "min_value", to: :min_value
            map "max_value", to: :max_value
            map "default_value", to: :default_value
          end
        end
      end
    end
  end
end