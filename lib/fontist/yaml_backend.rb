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
      # Pins the YAML adapter explicitly: lutaml-model auto-selects
      # yeptris for a format whenever the yeptris gem is in the bundle,
      # which would silently switch YAML parsing and dumping (and its
      # line-wrap behavior) for every model in the process. The yeptris
      # YAML engine activates only when explicitly enabled with
      # FONTIST_YAML=yeptris; otherwise the standard Psych engine is
      # pinned, because the yeptris x86_64-linux and Windows builds
      # currently mis-parse some plain scalars as single-element Arrays
      # (leptris/yeptris#863). Flip the default once that parity fix
      # lands.
      #
      # Returns the activated adapter class.
      def activate!
        adapter =
          if enabled? && yeptris_available?
            Yaml::YeptrisAdapter
          else
            Lutaml::Yaml::Adapter::StandardAdapter
          end

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
