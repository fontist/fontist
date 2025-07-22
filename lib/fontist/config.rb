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
      attr = key.to_sym
      unless default_values.key?(attr)
        raise Errors::InvalidConfigAttributeError,
              "No such attribute '#{attr}' exists."
      end

      v = normalize_value(value)
      if respond_to?("#{attr}=")
        public_send("#{attr}=", v)
      else
        @custom_values[attr] = v
      end

      persist
    end

    def delete(key)
      @custom_values.delete(key.to_sym)

      persist
    end

    def default_value(key)
      default_values[key.to_sym]
    end

    def default_values
      { fonts_path: Fontist.fontist_path.join("fonts"),
        open_timeout: 60,
        read_timeout: 60,
        google_fonts_key: nil }
    end

    def persist
      values = @custom_values.transform_keys(&:to_s)
      FileUtils.mkdir_p(File.dirname(Fontist.config_path))
      File.write(Fontist.config_path, YAML.dump(values))
    end

    def load
      @custom_values = load_config_file
    end

    def fonts_path=(value)
      @custom_values[:fonts_path] = File.expand_path(value)
    end

    private

    def load_config_file
      return {} unless File.exist?(Fontist.config_path)

      YAML.load_file(Fontist.config_path).transform_keys(&:to_sym)
    end

    def normalize_value(value)
      return value.to_i if value.to_i.to_s == value # detect integer

      value
    end
  end
end
