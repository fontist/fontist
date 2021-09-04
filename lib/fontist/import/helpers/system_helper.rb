module Fontist
  module Import
    module Helpers
      module SystemHelper
        class << self
          def run(command)
            Fontist.ui.say("Run `#{command}`") if Fontist.debug?

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
