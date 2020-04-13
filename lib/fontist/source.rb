require "yaml"
require "json"
require "ostruct"

module Fontist
  class Source
    def self.all
      new.all
    end

    def all
      source_data
    end

    private

    def source_data
      @source_data ||= JSON.parse(
        yaml_data.to_json, object_class: OpenStruct
      )
    end

    def yaml_data
      YAML.load(File.open(yaml_file))
    end

    def yaml_file
      Fontist.assets_path.join("source.yml")
    end
  end
end
