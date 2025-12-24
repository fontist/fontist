require "fileutils"
require "yaml"
require_relative "../import"
require_relative "../formula"
require_relative "google/font_database"
require_relative "google/api"

module Fontist
  module Import
    # Google Fonts importer using unified FontDatabase architecture
    #
    # Generates v4 formulas from Google Fonts API (TTF only) with OFL.txt from GitHub.
    # Downloads and parses fonts with Fontisan to extract accurate metadata.
    class GoogleFontsImporter
      def initialize(options = {})
        @api_key = options[:api_key] || ENV.fetch("GOOGLE_FONTS_API_KEY") do
          raise "GOOGLE_FONTS_API_KEY environment variable not set"
        end
        @source_path = options[:source_path] || raise("source_path required for v4 formula generation")
        @output_path = options[:output_path] || "./Formulas/google"
        @font_family = options[:font_family]
        @verbose = options[:verbose]
      end

      def import
        start_time = Time.now

        # Build v4 database (TTF static only with GitHub OFL.txt)
        log "Building v4 database from Google Fonts API and GitHub repository..."
        database = Google::FontDatabase.build_v4(
          api_key: @api_key,
          source_path: @source_path,
        )

        font_families = @font_family ? [@font_family] : database.all_fonts.map(&:family)

        results = { successful: 0, failed: 0, errors: [] }

        font_families.each do |family_name|
          import_font_from_api(database, family_name)
          results[:successful] += 1
          log "✓ Imported #{family_name}"
        rescue StandardError => e
          results[:failed] += 1
          results[:errors] << { font: family_name, error: e.message }
          log "✗ Failed #{family_name}: #{e.message}"
          log e.backtrace.join("\n") if @verbose
        end

        results[:duration] = Time.now - start_time
        results
      end

      private

      # Import font using v4 database
      def import_font_from_api(database, family_name)
        # Ensure output directory exists
        FileUtils.mkdir_p(@output_path)

        # FontDatabase generates complete v4 formula from API + GitHub
        paths = database.save_formulas(@output_path, family_name: family_name)

        if paths.nil? || paths.empty?
          raise "No formula generated for #{family_name}"
        end

        log "  Saved formula to: #{paths.first}" if @verbose
      end

      def log(message)
        puts message if @verbose
      end
    end
  end
end
