require "lutaml/model"

module Fontist
  class Config < Lutaml::Model::Serializable
    attribute :fonts_path, :string
    attribute :google_fonts_key, :string
    attribute :open_timeout, :integer
    attribute :read_timeout, :integer
    attribute :continue_on_checksum_mismatch, :boolean
    attribute :use_system_index, :boolean
    attribute :preferred_family, :boolean
    attribute :update_fontconfig, :boolean
    attribute :no_progress, :boolean
    attribute :fonts_install_location, :string
    attribute :user_fonts_path, :string
    attribute :system_fonts_path, :string

    key_value do
      map "fonts_path", to: :fonts_path
      map "google_fonts_key", to: :google_fonts_key
      map "open_timeout", to: :open_timeout
      map "read_timeout", to: :read_timeout
      map "continue_on_checksum_mismatch", to: :continue_on_checksum_mismatch
      map "use_system_index", to: :use_system_index
      map "preferred_family", to: :preferred_family
      map "update_fontconfig", to: :update_fontconfig
      map "no_progress", to: :no_progress
      map "fonts_install_location", to: :fonts_install_location
      map "user_fonts_path", to: :user_fonts_path
      map "system_fonts_path", to: :system_fonts_path
    end

    class << self
      def instance
        @instance ||= new.tap(&:load)
      end

      def reset
        @instance = nil
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

      # Gets fonts installation location
      # Priority: ENV > config file > default ("fontist")
      #
      # @return [Symbol] :fontist, :user, or :system
      def fonts_install_location
        value = ENV["FONTIST_INSTALL_LOCATION"] ||
          instance.custom_values[:fonts_install_location] ||
          "fontist"

        parse_location_value(value)
      end

      # Sets fonts installation location in config file
      #
      # @param location [String, Symbol] "fontist", "user", "system", or symbols
      def set_fonts_install_location(location)
        normalized = normalize_location_value(location)
        instance.set(:fonts_install_location, normalized)
      end

      # Gets user fonts path
      # Priority: ENV > config file > nil (use default in InstallLocation)
      #
      # @return [String, nil] User fonts path or nil for default
      def user_fonts_path
        ENV["FONTIST_USER_FONTS_PATH"] ||
          instance.custom_values[:user_fonts_path]
      end

      # Gets system fonts path
      # Priority: ENV > config file > nil (use default in InstallLocation)
      #
      # @return [String, nil] System fonts path or nil for default
      def system_fonts_path
        ENV["FONTIST_SYSTEM_FONTS_PATH"] ||
          instance.custom_values[:system_fonts_path]
      end

      private

      def parse_location_value(value)
        case value.to_s.downcase.tr("_", "-")
        when "fontist", "fontist-library"
          :fontist
        when "user"
          :user
        when "system"
          :system
        else
          Fontist.ui.error("Invalid install location: #{value}, using 'fontist'")
          :fontist
        end
      end

      def normalize_location_value(value)
        case value.to_s.downcase.tr("_", "-")
        when "fontist", "fontist-library"
          "fontist"
        when "user"
          "user"
        when "system"
          "system"
        else
          raise Errors::InvalidConfigAttributeError,
                "Invalid location: #{value}. Use 'fontist', 'user', or 'system'"
        end
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

      # Expand fonts_path to absolute path
      v = File.expand_path(v.to_s) if attr == :fonts_path

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
        google_fonts_key: nil,
        fonts_install_location: nil }
    end

    def persist
      config_model = self.class.new
      @custom_values.each do |key, value|
        if config_model.respond_to?("#{key}=")
          config_model.send("#{key}=",
                            value)
        end
      end

      FileUtils.mkdir_p(File.dirname(Fontist.config_path))
      config_model.to_file(Fontist.config_path)
    end

    def load
      @custom_values = load_config_file
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
