module Fontist
  class Config
    include Singleton

    def initialize
      @custom_values = load_config_file
    end

    def values
      default_values.merge(@custom_values)
    end

    def custom_values
      @custom_values
    end

    def set(key, value)
      v = normalize_value(value)
      @custom_values[key.to_s] = v

      persist
    end

    def delete(key)
      @custom_values.delete(key.to_s)

      persist
    end

    def default_value(key)
      default_values[key.to_s]
    end

    def default_values
      { open_timeout: 10,
        read_timeout: 10 }.transform_keys(&:to_s)
    end

    def persist
      File.write(Fontist.config_path, YAML.dump(@custom_values))
    end

    def load
      @custom_values = load_config_file
    end

    private

    def load_config_file
      return {} unless File.exist?(Fontist.config_path)

      YAML.load_file(Fontist.config_path)
    end

    def normalize_value(value)
      return value.to_i if value.to_i.to_s == value # detect integer

      value
    end
  end
end
