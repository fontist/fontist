require "lutaml/model"
require_relative "resource"

module Fontist
  # Resource Collection
  # NOTE: This class is kept for backward compatibility with external consumers
  # but is no longer used internally by Formula (which uses Resource, collection: true).
  class ResourceCollection < Lutaml::Model::Collection
    instances :resources, Resource

    key_value do
      map_key to_instance: :name
      map_instances to: :resources
    end

    def empty?
      resources.nil? || Array(resources).all?(&:empty?)
    end
  end
end
