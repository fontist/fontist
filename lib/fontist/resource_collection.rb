require "lutaml/model"
require_relative "resource"

module Fontist
  # Resource Collection
  class ResourceCollection < Lutaml::Model::Collection
    instances :resources, Resource

    key_value do
      root "resources"
      map to: :resources
      map_key to_instance: :name
    end

    def empty?
      resources.nil? || Array(resources).all?(&:empty?)
    end
  end
end
