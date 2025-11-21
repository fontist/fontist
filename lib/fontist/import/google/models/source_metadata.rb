# frozen_string_literal: true

require "lutaml/model"
require_relative "file_metadata"

module Fontist
  module Import
    module Google
      module Models
        # Model for source repository metadata
        class SourceMetadata < Lutaml::Model::Serializable
          attribute :repository_url, :string
          attribute :commit, :string
          attribute :archive_url, :string
          attribute :branch, :string
          attribute :config_yaml, :string
          attribute :files, FileMetadata, collection: true

          key_value do
            map "repository_url", to: :repository_url
            map "commit", to: :commit
            map "archive_url", to: :archive_url
            map "branch", to: :branch
            map "config_yaml", to: :config_yaml
            map "files", to: :files
          end
        end
      end
    end
  end
end