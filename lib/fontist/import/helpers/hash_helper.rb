module Fontist
  module Import
    module Helpers
      module HashHelper
        class << self
          # Converts a formula hash to string-keyed plain data. Values
          # that are lutaml-model models join the document through their
          # own to_hash serializer (the json gem used to call to_json on
          # them implicitly during traversal; Yeptris::JSON does not).
          def stringify_keys(hash)
            deep_stringify(hash)
          end

          private

          def deep_stringify(value)
            case value
            when Hash then value.to_h { |k, v| [k.to_s, deep_stringify(v)] }
            when Array then value.map { |v| deep_stringify(v) }
            else deep_stringify_model(value)
            end
          end

          def deep_stringify_model(value)
            return value unless value.respond_to?(:to_hash)

            deep_stringify(value.to_hash)
          end
        end
      end
    end
  end
end
