require_relative "base"

module Fontist
  module Import
    module Google
      module DataSources
        # Data source for fetching WOFF2 (Web Open Font Format 2) fonts
        #
        # This data source fetches fonts from the Google Fonts API with the
        # WOFF2 capability. The response includes fonts in WOFF2 format, which
        # is optimized for web delivery.
        class Woff2 < Base
          CAPABILITY = "WOFF2".freeze

          # Initialize a new WOFF2 data source
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
