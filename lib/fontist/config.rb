require "lutaml/model"

module Fontist
  class Config < Lutaml::Model::Serializable
    attribute :fonts_path, :string
    attribute :open_timeout, :integer
    attribute :read_timeout, :integer
    attribute :continue_on_checksum_mismatch, :boolean
    attribute :use_system_index, :boolean
    attribute :preferred_family, :boolean
    attribute :update_fontconfig, :boolean
    attribute :no_progress, :boolean

    key_value do
      map "fonts_path", to: :fonts_path
      map "open_timeout", to: :open_timeout
      map "read_timeout", to: :read_timeout
      map "continue_on_checksum_mismatch", to: :continue_on_checksum_mismatch
      map "use_system_index", to: :use_system_index
      map "preferred_family", to: :preferred_family
      map "update_fontconfig", to: :update_fontconfig
      map "no_progress", to: :no_progress
    end

    class << self
      def instance
        @instance ||= new.tap(&:load)
      end

      def values
        instance.values
      end

      def custom_values
        instance.custom_values
      end

      def set(key, value)
        instance.set(key, value)
      end

      def delete(key)
        instance.delete(key)
      end

      def default_value(key)
        instance.default_value(key)
      end

      def from_file(path)
        return new unless File.exist?(path)

        content = File.read(path)
        from_yaml(content)
      end
    end

    def initialize(**attrs)
      @custom_values = {}
      super
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
      @custom_values[attr] = v
      send("#{attr}=", v) if respond_to?("#{attr}=")

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
      config_model = self.class.new
      @custom_values.each do |key, value|
        config_model.send("#{key}=", value) if config_model.respond_to?("#{key}=")
      end

      FileUtils.mkdir_p(File.dirname(Fontist.config_path))
      config_model.to_file(Fontist.config_path)
    end

    def load
      @custom_values = load_config_file
    end

    def fonts_path=(value)
      @custom_values[:fonts_path] = File.expand_path(value.to_s)
      @fonts_path = @custom_values[:fonts_path]
    end

    def to_file(path)
      File.write(path, to_yaml)
    end

    private

    def load_config_file
      return {} unless File.exist?(Fontist.config_path)

      self.class.from_file(Fontist.config_path)&.to_hash&.transform_keys(&:to_sym) || {}
    end

    def normalize_value(value)
      return value.to_i if value.to_i.to_s == value # detect integer

      value
    end
  end
end
