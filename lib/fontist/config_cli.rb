module Fontist
  class ConfigCLI < Thor
    include CLI::ClassOptions

    STATUS_SUCCESS = 0

    desc "show", "Show values of the current config"
    def show
      handle_class_options(options)
      values = Config.instance.custom_values
      Fontist.ui.success("Current config:")
      Fontist.ui.success(format_hash(values))
      STATUS_SUCCESS
    end

    desc "set KEY VALUE", "Set the KEY attribute to VALUE in the current config"
    def set(key, value)
      handle_class_options(options)
      Config.instance.set(key, value)
      Fontist.ui.success("'#{key}' set to '#{value}'.")
      STATUS_SUCCESS
    end

    desc "delete KEY", "Delete the KEY attribute from the current config"
    def delete(key)
      handle_class_options(options)
      Config.instance.delete(key)
      Fontist.ui.success(
        "'#{key}' reset to default ('#{Config.instance.default_value(key)}').",
      )
      STATUS_SUCCESS
    end

    private

    def format_hash(hash)
      YAML.dump(hash).gsub(/^---.*$/, "").strip
    end
  end
end
