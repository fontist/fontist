require_relative "models/axis"
require_relative "models/font_variant"
require_relative "models/font_family"
require_relative "data_sources/base"
require_relative "data_sources/ttf"
require_relative "data_sources/vf"
require_relative "data_sources/woff2"
require_relative "font_database"

module Fontist
  module Import
    module Google
      # Facade for accessing the unified Google Fonts database
      #
      # This class provides a clean interface for accessing Google Fonts data
      # by integrating data from three API endpoints (TTF, VF, WOFF2) into a
      # unified database.
      #
      # @example Basic usage
      #   fonts = Api.items
      #   roboto = Api.font_by_name("Roboto")
      #
      # @example Filtering
      #   sans_serif = Api.by_category("sans-serif")
      #   variable = Api.variable_fonts_only
      #
      # @example Raw endpoint access
      #   ttf_data = Api.ttf_data
      #   vf_data = Api.vf_data
      class Api
        class << self
          # Get unified font database instance
          #
          # @return [FontDatabase] the unified database
          def database
            @database ||= build_database
          end

          # Get all font families (main entry point)
          #
          # @return [Array<Models::FontFamily>] array of all font families
          def items
            database.all_fonts
          end

          # Alias for items
          #
          # @return [Array<Models::FontFamily>] array of all font families
          def font_families
            items
          end

          # Find a specific font family by name
          #
          # @param name [String] the font family name
          # @return [Models::FontFamily, nil] the font family if found
          def font_by_name(name)
            database.font_by_name(name)
          end

          # Filter fonts by category
          #
          # @param category [String] the category (e.g., "sans-serif")
          # @return [Array<Models::FontFamily>] fonts in the category
          def by_category(category)
            database.by_category(category)
          end

          # Get only variable fonts (fonts with axes)
          #
          # @return [Array<Models::FontFamily>] variable font families
          def variable_fonts_only
            database.variable_fonts_only
          end

          # Get only static fonts (fonts without axes)
          #
          # @return [Array<Models::FontFamily>] static font families
          def static_fonts_only
            database.static_fonts_only
          end

          # Get count of fonts by type
          #
          # @return [Hash] hash with counts of total, variable, and static
          def fonts_count
            database.fonts_count
          end

          # Get raw TTF endpoint data (for debugging)
          #
          # @return [Array<Models::FontFamily>] raw data from TTF endpoint
          def ttf_data
            ttf_client.fetch
          end

          # Get raw VF endpoint data (for debugging)
          #
          # @return [Array<Models::FontFamily>] raw data from VF endpoint
          def vf_data
            vf_client.fetch
          end

          # Get raw WOFF2 endpoint data (for debugging)
          #
          # @return [Array<Models::FontFamily>] raw data from WOFF2 endpoint
          def woff2_data
            woff2_client.fetch
          end

          # Clear all caches (clients + database)
          #
          # @return [void]
          def clear_cache
            ttf_client.clear_cache
            vf_client.clear_cache
            woff2_client.clear_cache
            @database = nil
          end

          private

          # Build unified font database from three clients
          #
          # @return [FontDatabase] the unified database
          def build_database
            FontDatabase.new(
              ttf_data: ttf_client.fetch,
              vf_data: vf_client.fetch,
              woff2_data: woff2_client.fetch,
              version: 5  # Use v5 to include variable fonts
            )
          end

          # Get TTF data source instance
          #
          # @return [DataSources::Ttf] the TTF data source
          def ttf_client
            @ttf_client ||= DataSources::Ttf.new(api_key: api_key)
          end

          # Get VF data source instance
          #
          # @return [DataSources::Vf] the VF data source
          def vf_client
            @vf_client ||= DataSources::Vf.new(api_key: api_key)
          end

          # Get WOFF2 data source instance
          #
          # @return [DataSources::Woff2] the WOFF2 data source
          def woff2_client
            @woff2_client ||= DataSources::Woff2.new(api_key: api_key)
          end

          # Get API key from Fontist configuration
          #
          # @return [String] the Google Fonts API key
          def api_key
            Fontist.google_fonts_key
          end
        end
      end
    end
  end
end