require_relative "base"

module Fontist
  module Import
    module Google
      module DataSources
        # Data source for fetching TTF (TrueType Font) format fonts
        #
        # This data source fetches fonts from the standard Google Fonts API
        # endpoint, which returns font files in TTF format.
        class Ttf < Base
          # Initialize a new TTF data source
          #
          # @param api_key [String] Google Fonts API key
          def initialize(api_key:)
            super(api_key: api_key, capability: nil)
          end
        end
      end
    end
  end
end