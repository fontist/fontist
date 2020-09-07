module Fontist
  module Import
    module Helpers
      module HashHelper
        class << self
          def stringify_keys(hash)
            JSON.parse(hash.to_json)
          end
        end
      end
    end
  end
end
