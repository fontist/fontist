module Fontist
  class ConfigCLI < Thor
    include CLI::ClassOptions

    desc "show", "Show values of the current config"
    def show
      handle_class_options(options)
      values = Config.instance.custom_values

      if values.empty?
        Fontist.ui.success("Config is empty.")
      else
        Fontist.ui.success("Current config:")
        Fontist.ui.success(format_hash(values))
      end

      CLI::STATUS_SUCCESS
    end

    desc "set KEY VALUE", "Set the KEY attribute to VALUE in the current config"
    def set(key, value)
      handle_class_options(options)
      Config.instance.set(key, value)
      Fontist.ui.success("'#{key}' set to '#{value}'.")
      CLI::STATUS_SUCCESS
    rescue Errors::InvalidConfigAttributeError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_INVALID_CONFIG_ATTRIBUTE
    end

    desc "delete KEY", "Delete the KEY attribute from the current config"
    def delete(key)
      handle_class_options(options)
      Config.instance.delete(key)
      Fontist.ui.success(
        "'#{key}' reset to default ('#{Config.instance.default_value(key)}').",
      )
      CLI::STATUS_SUCCESS
    end

    desc "keys", "Print all available config attributes"
    def keys
      handle_class_options(options)
      Fontist.ui.say("Available keys:")
      Config.instance.default_values.each do |key, value|
        Fontist.ui.say("#{key} (default: #{value})")
      end
      CLI::STATUS_SUCCESS
    end

    private

    def format_hash(hash)
      h = hash.transform_keys(&:to_s)
      YAML.dump(h).gsub(/^---.*$/, "").strip
    end
  end
end
