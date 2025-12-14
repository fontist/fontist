# frozen_string_literal: true

require "lutaml/model"

module Fontist
  module Import
    module Google
      module Models
        # Model for source file mapping metadata
        class FileMetadata < Lutaml::Model::Serializable
          attribute :source_file, :string
          attribute :dest_file, :string

          key_value do
            map "source_file", to: :source_file
            map "dest_file", to: :dest_file
          end
        end
      end
    end
  end
end
