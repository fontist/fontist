require "fileutils"
require "yaml"

module Fontist
  module Import
    # Migrate v4 formulas to v5 schema
    #
    # This script converts existing v4 formula files to v5 format by:
    # 1. Adding schema_version: 5
    # 2. Detecting format from file extensions in resources
    # 3. Detecting variable fonts from filename patterns
    #
    # Usage:
    #   Fontist::Import::V4ToV5Migrator.new(input_path, output_path).migrate_all
    #
    class V4ToV5Migrator
      FONT_EXTENSIONS = %w[ttf otf woff woff2 ttc otc dfont].freeze
      ARCHIVE_EXTENSIONS = %w[zip tar gz tgz bz2 7z rar exe cab].freeze

      def initialize(input_path, output_path = nil, options = {})
        @input_path = input_path
        @output_path = output_path || input_path
        @verbose = options[:verbose]
        @dry_run = options[:dry_run]
      end

      # Migrate all formulas in the input path
      #
      # @return [Hash] results with counts of migrated, skipped, failed
      def migrate_all
        results = { migrated: 0, skipped: 0, failed: 0, errors: [] }

        files = formula_files
        log "Found #{files.size} formula file(s) to process"

        files.each do |path|
          result = migrate_file(path)
          case result
          when :migrated
            results[:migrated] += 1
          when :skipped
            results[:skipped] += 1
          when :failed
            results[:failed] += 1
          end
        rescue StandardError => e
          results[:failed] += 1
          results[:errors] << { formula: path, error: e.message }
          log "✗ Failed #{File.basename(path)}: #{e.message}"
        end

        log_summary(results)
        results
      end

      # Migrate a single formula file
      #
      # @param path [String] path to formula file
      # @return [Symbol] :migrated, :skipped, or :failed
      def migrate_file(path)
        # Load formula
        formula_data = YAML.load_file(path)

        # Skip if already v5
        if formula_data["schema_version"] == 5
          log "  Already v5: #{File.basename(path)}"
          return :skipped
        end

        # Add schema_version: 5
        formula_data = add_schema_version(formula_data)

        # Upgrade resources with format metadata
        formula_data = upgrade_resources(formula_data) if formula_data["resources"]

        # Calculate output path
        output_file = output_path_for(path)

        # Save if not dry run
        if @dry_run
          log "  Would save: #{output_file}"
        else
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, YAML.dump(formula_data))
          log "  Saved: #{output_file}"
        end

        :migrated
      end

      private

      def formula_files
        if File.file?(@input_path)
          [@input_path]
        elsif File.directory?(@input_path)
          Dir.glob(File.join(@input_path, "**/*.yml")).sort
        else
          []
        end
      end

      def output_path_for(input_file)
        return input_file if @input_path == @output_path

        # Calculate relative path and map to output
        relative = input_file.sub(@input_path, "")
        File.join(@output_path, relative).sub(%r{/+}, "/")
      end

      def add_schema_version(formula_data)
        # Insert schema_version at the beginning for clean YAML output
        { "schema_version" => 5 }.merge(formula_data)
      end

      def upgrade_resources(formula_data)
        formula_data["resources"].each do |resource_name, resource_data|
          next unless resource_data.is_a?(Hash)

          # Skip archives - they don't have format
          next if archive_resource?(resource_name, resource_data)

          # Add format if missing
          unless resource_data["format"]
            format = detect_format(resource_name, resource_data)
            resource_data["format"] = format if format
          end

          # Add variable_axes if missing and detected
          unless resource_data["variable_axes"]
            axes = detect_variable_axes(resource_name, resource_data)
            resource_data["variable_axes"] = axes if axes&.any?
          end
        end

        formula_data
      end

      def archive_resource?(resource_name, resource_data)
        return true if archive_extension?(resource_name)

        urls = Array(resource_data["urls"] || resource_data["files"])
        urls.any? { |url| archive_extension?(url) }
      end

      def archive_extension?(path)
        path =~ /\.(#{ARCHIVE_EXTENSIONS.join('|')})(?:\?|$)/i
      end

      def detect_format(resource_name, resource_data)
        # Try from resource name
        format = format_from_name(resource_name)
        return format if format

        # Try from URLs
        urls = Array(resource_data["urls"] || resource_data["files"])
        urls.each do |url|
          format = format_from_url(url)
          return format if format
        end

        # Try from files array
        files = Array(resource_data["files"])
        files.each do |file|
          format = format_from_name(file)
          return format if format
        end

        nil
      end

      def format_from_name(name)
        if name =~ /\.(\w+)(?:\?|$)/
          ext = Regexp.last_match(1).downcase
          return ext if FONT_EXTENSIONS.include?(ext)
        end
        nil
      end

      def format_from_url(url)
        filename = url.split("/").last.split("?").first
        format_from_name(filename)
      end

      def detect_variable_axes(resource_name, resource_data)
        # Try from resource name
        axes = axes_from_name(resource_name)
        return axes if axes.any?

        # Try from URLs
        urls = Array(resource_data["urls"] || resource_data["files"])
        urls.each do |url|
          axes = axes_from_name(url)
          return axes if axes.any?
        end

        # Try from files array
        files = Array(resource_data["files"])
        files.each do |file|
          axes = axes_from_name(file)
          return axes if axes.any?
        end

        []
      end

      def axes_from_name(name)
        if name =~ /\[([^\]]+)\]/
          Regexp.last_match(1).split(",").map(&:strip)
        else
          []
        end
      end

      def log(message)
        puts message if @verbose
      end

      def log_summary(results)
        return unless @verbose

        puts "\n#{'=' * 60}"
        puts "Migration Summary"
        puts "=" * 60
        puts "  Migrated: #{results[:migrated]}"
        puts "  Skipped:  #{results[:skipped]}"
        puts "  Failed:   #{results[:failed]}"

        if results[:errors].any?
          puts "\nErrors:"
          results[:errors].each do |error|
            puts "  - #{error[:formula]}: #{error[:error]}"
          end
        end
        puts "=" * 60
      end
    end
  end
end
