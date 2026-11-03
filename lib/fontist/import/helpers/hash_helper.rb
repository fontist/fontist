module Fontist
  module Import
    module Helpers
      module HashHelper
        class << self
          def stringify_keys(hash)
            Fontist::JSON.parse(Fontist::JSON.dump(hash))
          end
        end
      end
    end
  end
end
