require_relative "base"

module Fontist
  module Import
    module Google
      module DataSources
        # Data source for fetching Variable Fonts
        #
        # This data source fetches fonts from the Google Fonts API with the VF
        # (Variable Fonts) capability. The response includes fonts that support
        # variable font capabilities, with axes data for those that have it.
        #
        # Note: The VF endpoint returns both variable and static fonts.
        # Fonts without axes are static fonts that support the VF capability
        # but don't have variable font axes.
        class Vf < Base
          CAPABILITY = "VF"

          # Initialize a new Variable Fonts data source
          #
          # @param api_key [String] Google Fonts API key
          def initialize(api_key:)
            super(api_key: api_key, capability: CAPABILITY)
          end
        end
      end
    end
  end
end