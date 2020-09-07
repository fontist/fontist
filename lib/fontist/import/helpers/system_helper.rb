module Fontist
  module Import
    module Helpers
      module SystemHelper
        class << self
          def run(command)
            puts "Run `#{command}`" unless ENV.fetch("TEST_ENV", "") === "CI"
            result = `#{command}`
            unless $CHILD_STATUS.to_i.zero?
              raise Errors::BinaryCallError,
                    "Failed to run #{command}, status: #{$CHILD_STATUS}"
            end

            result
          end
        end
      end
    end
  end
end
