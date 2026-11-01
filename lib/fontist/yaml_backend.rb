# frozen_string_literal: true

module Fontist
  # Model YAML engine selection.
  #
  # When the yeptris gem is available, model YAML (formula and index
  # documents, via lutaml-model) is parsed through its native loader -
  # measured 4x faster than Psych on those artifacts. The gem is an
  # optional consumer-side dependency (it needs Ruby >= 3.0, above
  # fontist's floor), so absence falls back to Psych silently.
  # FONTIST_YAML=psych forces the standard engine.
  module YamlBackend
    ENV_KEY = "FONTIST_YAML"

    class << self
      # Returns the activated adapter class, or nil when the standard
      # engine stays in place (flag set, or yeptris unavailable)
      def activate!
        return nil if forced_standard?
        return nil unless yeptris_available?

        adapter = Yaml::YeptrisAdapter
        Lutaml::Model::AdapterResolver.set_adapter_class(:yaml, adapter)

        adapter
      end

      def forced_standard?
        ENV[ENV_KEY] == "psych"
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
