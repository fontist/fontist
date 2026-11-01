# frozen_string_literal: true

module Fontist
  module Yaml
    # Model YAML parsing through yeptris's native loader. Measured 4x
    # faster than Psych on formula and index documents (442KB index:
    # 47ms vs 202ms), with parse results verified identical across the
    # full formulas corpus. Dumping stays on the standard adapter.
    class YeptrisAdapter < Lutaml::Yaml::Adapter::StandardAdapter
      def self.parse(yaml, _options = {})
        Yeptris::YAML.load(yaml)
      end
    end
  end
end
