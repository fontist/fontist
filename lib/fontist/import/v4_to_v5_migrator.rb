require "fileutils"
require "yaml"

module Fontist
  module Import
    # Migrate v4 formulas to v5 schema, and verify/fix existing v5 formulas
    #
    # This script converts existing v4 formula files to v5 format and
    # validates/repairs existing v5 formulas by:
    # 1. Adding schema_version: 5
    # 2. Detecting format from file extensions in resources
    # 3. Detecting variable fonts from filename patterns
    # 4. Fixing Google files arrays (URLs → basenames)
    # 5. Adding css_url to woff2 Google resources
    # 6. Filling nil style metadata (formats, variable_font, variable_axes)
    #
    # Re-running on already-migrated formulas is safe and idempotent.
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
        results = { migrated: 0, verified: 0, skipped: 0, failed: 0, errors: [] }

        files = formula_files
        log "Found #{files.size} formula file(s) to process"

        files.each do |path|
          result = migrate_file(path)
          case result
          when :migrated
            results[:migrated] += 1
          when :verified
            results[:verified] += 1
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
      # @return [Symbol] :migrated, :verified, or :skipped
      def migrate_file(path)
        formula_data = YAML.load_file(path)
        already_v5 = formula_data["schema_version"] == 5

        # Add schema_version: 5 if not present
        formula_data = add_schema_version(formula_data) unless already_v5

        # Upgrade/verify resources
        changed = false
        if formula_data["resources"]
          changed |= upgrade_resources(formula_data)
          changed |= verify_resources(formula_data)
        end

        # Upgrade/verify styles
        if formula_data["fonts"] || formula_data["font_collections"]
          changed |= migrate_styles(formula_data)
        end

        # Nothing to do if already v5 and no fixes needed
        if already_v5 && !changed
          log "  OK: #{File.basename(path)}"
          return :skipped
        end

        # Save
        output_file = output_path_for(path)
        if @dry_run
          log "  Would #{already_v5 ? 'fix' : 'migrate'}: #{output_file}"
        else
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, YAML.dump(formula_data))
          log "  #{already_v5 ? 'Fixed' : 'Migrated'}: #{output_file}"
        end

        already_v5 ? :verified : :migrated
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
        return input_file if @output_path.nil? || @input_path == @output_path

        # If input is a file and output is a directory, use the same filename
        if File.file?(@input_path) && File.directory?(@output_path)
          return File.join(@output_path, File.basename(input_file))
        end

        # Calculate relative path and map to output
        relative = input_file.sub(@input_path, "")
        File.join(@output_path, relative).sub(%r{/+}, "/")
      end

      def add_schema_version(formula_data)
        # Insert schema_version at the beginning for clean YAML output
        { "schema_version" => 5 }.merge(formula_data)
      end

      def upgrade_resources(formula_data)
        changed = false

        formula_data["resources"].each do |resource_name, resource_data|
          next unless resource_data.is_a?(Hash)

          # Skip archives - they don't have format
          next if archive_resource?(resource_name, resource_data)

          # Add format if missing
          unless resource_data["format"]
            format = detect_format(resource_name, resource_data)
            if format
              resource_data["format"] = format
              changed = true
            end
          end

          # Add variable_axes if missing and detected
          unless resource_data["variable_axes"]
            axes = detect_variable_axes(resource_name, resource_data)
            if axes&.any?
              resource_data["variable_axes"] = axes
              changed = true
            end
          end
        end

        changed
      end

      # Verify and fix v5 resource data:
      # - files should be basenames (not full URLs)
      # - woff2 Google resources should have css_url
      def verify_resources(formula_data)
        changed = false

        formula_data["resources"].each do |_name, resource_data|
          next unless resource_data.is_a?(Hash)

          changed |= fix_files_basenames(resource_data)
          changed |= fix_css_url(resource_data)
        end

        changed
      end

      # Where files == urls, replace files with basenames
      def fix_files_basenames(resource_data)
        files = Array(resource_data["files"])
        urls = Array(resource_data["urls"])

        return false if files.empty? || urls.empty?
        return false unless files == urls

        resource_data["files"] = urls.map { |url| url.split("/").last.split("?").first }
        true
      end

      # Add css_url to woff2 resources with source: google + family
      def fix_css_url(resource_data)
        return false if resource_data["css_url"]
        return false unless resource_data["source"] == "google"
        return false unless resource_data["family"]
        return false unless resource_data["format"] == "woff2"

        family = resource_data["family"].gsub(" ", "+")
        resource_data["css_url"] = "https://fonts.googleapis.com/css2?family=#{family}"
        true
      end

      def migrate_styles(formula_data)
        changed = false
        resource_meta = build_resource_metadata(formula_data["resources"])

        all_style_containers = Array(formula_data["fonts"])
        Array(formula_data["font_collections"]).each do |collection|
          next unless collection.is_a?(Hash)

          all_style_containers.concat(Array(collection["fonts"]))
        end

        all_style_containers.each do |font_family|
          next unless font_family.is_a?(Hash) && font_family["styles"]

          Array(font_family["styles"]).each do |style|
            next unless style.is_a?(Hash)

            font_file = style["font"] || style["source_font"]
            next unless font_file

            ext = font_file[/\.(\w+)$/, 1]&.downcase

            # Fix formats: set if nil, empty, or contains nil entries
            if needs_fix?(style["formats"])
              if ext && FONT_EXTENSIONS.include?(ext)
                style["formats"] = [ext]
                changed = true
              end
            end

            # Fix variable_font / variable_axes
            if font_file =~ /\[([^\]]+)\]/
              axes = Regexp.last_match(1).split(",").map(&:strip)
              unless style["variable_font"] == true
                style["variable_font"] = true
                changed = true
              end
              if needs_fix?(style["variable_axes"])
                style["variable_axes"] = axes
                changed = true
              end
            else
              if style["variable_font"].nil?
                style["variable_font"] = false
                changed = true
              end
            end

            # Set source_resource if missing
            unless style["source_resource"]
              sr = find_source_resource(font_file, formula_data["resources"])
              if sr
                style["source_resource"] = sr
                changed = true
              end
            end

            # Enrich from resource metadata
            if style["source_resource"] && resource_meta[style["source_resource"]]
              meta = resource_meta[style["source_resource"]]
              if needs_fix?(style["formats"]) && meta[:format]
                style["formats"] = [meta[:format]]
                changed = true
              end
              if meta[:variable_axes]&.any? && needs_fix?(style["variable_axes"])
                style["variable_font"] = true
                style["variable_axes"] = meta[:variable_axes]
                changed = true
              end
            end
          end
        end

        changed
      end

      # Check if a field needs fixing: nil, or array with nil entries
      def needs_fix?(value)
        return true if value.nil?
        return true if value.is_a?(Array) && (value.empty? || value.any?(&:nil?))

        false
      end

      def build_resource_metadata(resources)
        meta = {}
        return meta unless resources.is_a?(Hash)

        resources.each do |name, data|
          next unless data.is_a?(Hash)

          meta[name] = {
            format: data["format"],
            variable_axes: data["variable_axes"],
          }
        end
        meta
      end

      def find_source_resource(font_file, resources)
        return nil unless resources.is_a?(Hash)

        resources.each do |name, data|
          next unless data.is_a?(Hash)

          files = Array(data["files"])
          return name if files.any? { |f| File.basename(f) == File.basename(font_file) }
        end

        return resources.keys.first if resources.size == 1

        nil
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
        puts "  Verified: #{results[:verified]}" if results[:verified].to_i > 0
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
