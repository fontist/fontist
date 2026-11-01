# frozen_string_literal: true

module Fontist
  # Model YAML engine selection.
  #
  # The yeptris engine (native loader, measured 4x faster than Psych on
  # large documents) activates only when explicitly enabled with
  # FONTIST_YAML=yeptris. It is off by default because the yeptris
  # x86_64-linux and Windows builds currently mis-parse some plain
  # scalars as single-element Arrays (leptris/yeptris#863); flip the
  # default once that parity fix lands.
  module YamlBackend
    ENV_KEY = "FONTIST_YAML"
    ENABLED_VALUE = "yeptris"

    class << self
      # Returns the activated adapter class, or nil when the standard
      # engine stays in place (flag unset, or yeptris unavailable)
      def activate!
        return nil unless enabled?
        return nil unless yeptris_available?

        adapter = Yaml::YeptrisAdapter
        Lutaml::Model::AdapterResolver.set_adapter_class(:yaml, adapter)

        adapter
      end

      def enabled?
        ENV[ENV_KEY] == ENABLED_VALUE
      end

      def yeptris_available?
        require "yeptris"
        true
      rescue LoadError
        false
      end
    end
  end
end
