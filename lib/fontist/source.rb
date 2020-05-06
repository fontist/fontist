require "yaml"
require "json"
require "ostruct"

module Fontist
  class Source
    def self.all
      new.all
    end

    def self.formulas
      new.formulas
    end

    def all
      source_data
    end

    def formulas
      formulas_data
    end

    private

    def source_data
      @source_data ||= parse_to_object(yaml_data)
    end

    def parse_to_object(data)
      JSON.parse(data.to_json, object_class: OpenStruct)
    end

    def formulas_data
      @formulas_data ||= parse_to_object(load_formulas)
    end

    def load_formulas
      Hash.new.tap do |formulas|
        source_data.remote.formulas.map do |formula_file|
          formula_data = yaml_data(formula_file)

          if formula_data
            key = formula_data.keys.first
            formulas[key] = formula_data[key]
          end
        end
      end
    end

    def yaml_file(file)
      Fontist.data_path.join(file)
    end

    def yaml_data(file_name = "source.yml")
      YAML.load(File.open(yaml_file(file_name)))
    end
  end
end
