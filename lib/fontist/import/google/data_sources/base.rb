require "net/http"
require "json"
require "uri"
require_relative "../models/font_family"

module Fontist
  module Import
    module Google
      module DataSources
        # Base class for Google Fonts API data source clients
        #
        # Provides common functionality for fetching data from the API,
        # caching responses, and parsing JSON into FontFamily models.
        class Base
          BASE_URL = "https://www.googleapis.com/webfonts/v1/webfonts".freeze

          attr_reader :api_key, :capability

          # Initialize a new API data source client
          #
          # @param api_key [String] Google Fonts API key
          # @param capability [String, nil] Optional capability parameter
          def initialize(api_key:, capability: nil)
            @api_key = api_key
            @capability = capability
            @cache = nil
          end

          # Fetch and parse font families from the API
          #
          # @return [Array<FontFamily>] array of parsed font family models
          def fetch
            return @cache if @cache

            raw_data = fetch_raw
            @cache = parse_response(raw_data)
          end

          # Build the API URL with parameters
          #
          # @return [String] the complete API URL
          def url
            uri = URI(BASE_URL)
            params = { key: api_key }
            params[:capability] = capability if capability
            uri.query = URI.encode_www_form(params)
            uri.to_s
          end

          # Fetch raw JSON data from the API
          #
          # @return [Hash] parsed JSON response
          # @raise [RuntimeError] if the request fails
          def fetch_raw
            uri = URI(url)
            response = Net::HTTP.get_response(uri)

            unless response.is_a?(Net::HTTPSuccess)
              raise "API request failed: #{response.code} #{response.message}"
            end

            JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise "Failed to parse API response: #{e.message}"
          rescue StandardError => e
            raise "Failed to fetch from API: #{e.message}"
          end

          # Parse API response into FontFamily models
          #
          # Subclasses should override this method to customize parsing
          #
          # @param raw_data [Hash] the raw API response
          # @return [Array<FontFamily>] array of font family models
          def parse_response(raw_data)
            items = raw_data["items"] || []
            items.map { |item| parse_item(item) }
          end

          # Clear the internal cache
          #
          # @return [nil]
          def clear_cache
            @cache = nil
          end

          protected

          # Parse a single font item into a FontFamily model
          #
          # @param item [Hash] the raw item data
          # @return [FontFamily] the parsed font family
          def parse_item(item)
            Models::FontFamily.from_json(item.to_json)
          end
        end
      end
    end
  end
end
