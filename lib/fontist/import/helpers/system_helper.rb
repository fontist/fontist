module Fontist
  module Import
    module Helpers
      module SystemHelper
        class << self
          def run(command)
            Fontist::Helpers.run(command)
          end
        end
      end
    end
  end
end
