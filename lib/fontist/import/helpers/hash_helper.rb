module Fontist
  module Import
    module Helpers
      module HashHelper
        class << self
          def stringify_keys(hash)
            JSON.parse(hash.to_json)
          end

          def parse_to_object(data)
            JSON.parse(data.to_json, object_class: OpenStruct)
          end
        end
      end
    end
  end
end
