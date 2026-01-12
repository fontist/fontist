require "fileutils"
require "yaml"
require "paint"
require_relative "../import"
require_relative "../formula"
require_relative "google/font_database"
require_relative "google/api"
require_relative "import_display"

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
        @import_cache = options[:import_cache]
        @force = options[:force]
        @success_count = 0
        @failure_count = 0
        @skipped_count = 0
        @overwritten_count = 0
        @failures = []  # Track {name, reason} for each failure
      end

      def import
        start_time = Time.now

        # Display header with import cache
        display_header

        # Build database
        database = build_database

        # Get font list
        font_families = @font_family ? [@font_family] : database.all_fonts.map(&:family)

        if @verbose
          Fontist.ui.say("📦 Found #{Paint[font_families.size, :yellow, :bright]} font families to import")
          Fontist.ui.say("📁 Saving formulas to: #{Paint[@output_path, :cyan]}")
          Fontist.ui.say("")
        end

        # Process fonts
        process_fonts(database, font_families)

        # Display summary
        display_summary(font_families.size, Time.now - start_time)

        # Display failures after summary
        display_failures

        build_results(Time.now - start_time)
      end

      private

      def display_header
        cache_path = @import_cache || Fontist.import_cache_path
        details = {
          source_path: @source_path,
          output_path: @output_path,
        }
        details[:font_filter] = @font_family if @font_family

        if @verbose
          ImportDisplay.header("Google Fonts", details, import_cache: cache_path)
        end
      end

      def build_database
        if @verbose
          Fontist.ui.say("🔨 Building font database from API...")
          ImportDisplay.debug_info("→ Fetching TTF endpoint data...")
        end

        database = Google::FontDatabase.build_v4(
          api_key: @api_key,
          source_path: @source_path,
        )

        if @verbose
          ImportDisplay.debug_info("→ Parsing GitHub metadata...")
          Fontist.ui.say("  #{Paint['✓', :green]} Database ready with #{Paint[database.all_fonts.size, :yellow, :bright]} font families")
          Fontist.ui.say("")
        end

        database
      end

      def process_fonts(database, font_families)
        font_families.each_with_index do |family_name, index|
          process_single_font(database, family_name, index + 1, font_families.size)
        end
      end

      def process_single_font(database, family_name, current, total)
        # Display progress
        ImportDisplay.progress(current, total, family_name) if @verbose

        # Check if formula already exists
        expected_path = predicted_formula_path(family_name)

        if expected_path && File.exist?(expected_path)
          if @force
            @overwritten_count += 1
            if @verbose
              Fontist.ui.say("  #{Paint['⚠', :yellow]} Overwriting existing formula: #{Paint[File.basename(expected_path), :yellow]}")
            end
          else
            @skipped_count += 1
            if @verbose
              Fontist.ui.say("  #{Paint['⊝', :yellow]} Skipped (already exists): #{Paint[File.basename(expected_path), :black, :bright]}")
              Fontist.ui.say("    #{Paint['ℹ', :blue]} Use #{Paint['--force', :cyan]} to overwrite existing formulas")
            end
            return
          end
        end

        start_time = Time.now
        paths = import_font_from_api(database, family_name)

        elapsed = Time.now - start_time
        @success_count += 1

        # Show actual filename created, not family name with .yml
        formula_filename = File.basename(paths.first) if paths&.first
        if @verbose
          Fontist.ui.say("  #{Paint['✓', :green]} Formula created: #{Paint[formula_filename || "#{family_name}.yml", :white]} #{Paint["(#{elapsed.round(2)}s)", :black, :bright]}")
        end
      rescue StandardError => e
        @failure_count += 1
        error_msg = e.message.length > 60 ? "#{e.message[0..60]}..." : e.message
        @failures << { name: family_name, reason: error_msg }
        Fontist.ui.say("  #{Paint['✗', :red]} Failed: #{Paint[error_msg, :red]}") if @verbose
      end

      # Predict formula path based on family name
      def predicted_formula_path(family_name)
        normalized_name = family_name.downcase.gsub(/[^a-z0-9]+/, '_')
        File.join(@output_path, "#{normalized_name}.yml")
      rescue StandardError
        nil
      end

      # Import font using v4 database
      def import_font_from_api(database, family_name)
        # Ensure output directory exists
        FileUtils.mkdir_p(@output_path)

        # FontDatabase generates complete v4 formula from API + GitHub
        paths = database.save_formulas(@output_path, family_name: family_name)

        if paths.nil? || paths.empty?
          raise "No formula generated for #{family_name}"
        end

        paths
      end

      def display_summary(total, duration)
        return unless @verbose

        Fontist.ui.say("")
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say(Paint["  📊 Import Summary", :cyan, :bright])
        Fontist.ui.say(Paint["═" * 80, :cyan])
        Fontist.ui.say("")

        success_rate = (@success_count.to_f / total * 100).round(1)

        Fontist.ui.say("  Total fonts:        #{Paint[total.to_s, :white]}")
        Fontist.ui.say("  #{Paint['✓', :green]} Successful:     #{Paint[@success_count.to_s, :green, :bright]} #{Paint["(#{success_rate}%)", :green]}")

        if @skipped_count > 0
          skip_rate = (@skipped_count.to_f / total * 100).round(1)
          Fontist.ui.say("  #{Paint['⊝', :yellow]} Skipped:        #{Paint[@skipped_count.to_s, :yellow]} #{Paint["(#{skip_rate}%)", :yellow]} #{Paint['(already exists)', :black, :bright]}")
        end

        if @overwritten_count > 0
          Fontist.ui.say("  #{Paint['⚠', :yellow]} Overwritten:    #{Paint[@overwritten_count.to_s, :yellow]}")
        end

        if @failure_count > 0
          fail_rate = (@failure_count.to_f / total * 100).round(1)
          Fontist.ui.say("  #{Paint['✗', :red]} Failed:         #{Paint[@failure_count.to_s, :red]} #{Paint["(#{fail_rate}%)", :red]}")
        end

        if @skipped_count > 0 && !@force
          Fontist.ui.say("")
          Fontist.ui.say("  #{Paint['💡 Tip:', :cyan]} Use #{Paint['--force', :cyan, :bright]} to overwrite existing formulas:")
          Fontist.ui.say("    fontist import google --source-path=<path> --force")
        end

        Fontist.ui.say("")

        if @success_count > (total * 0.5)
          Fontist.ui.say(Paint["  🎉 Great success! #{@success_count} formulas created!", :green, :bright])
        elsif @success_count > 0
          Fontist.ui.say(Paint["  👍 Keep going! #{@success_count} formulas created.", :yellow, :bright])
        end

        # Show failures if any
        if @failures.any?
          Fontist.ui.say("")
          Fontist.ui.say(Paint["═" * 80, :cyan])
          Fontist.ui.say(Paint["  ❌ Failed Imports", :red, :bright])
          Fontist.ui.say(Paint["═" * 80, :cyan])
          Fontist.ui.say("")

          @failures.each_with_index do |failure, index|
            Fontist.ui.say("  #{index + 1}. #{Paint[failure[:name], :yellow]} - #{Paint[failure[:reason], :red]}")
          end
        end

        Fontist.ui.say("")
      end

      def display_failures
        return if @failures.empty?

        Fontist.ui.say("")
        Fontist.ui.say(Paint["════════───────────────────────────────────────────────────────────────────────────────────────────────────────────────────", :red])
        Fontist.ui.say(Paint["  ✗ Failed fonts (#{@failure_count} total)", :red, :bold])
        Fontist.ui.say(Paint["════════───────────────────────────────────────────────────────────────────────────────────────────────────────────────────", :red])
        Fontist.ui.say("")

        @failures.each do |failure|
          Fontist.ui.say("  #{Paint['✗', :red]} #{failure[:name]} - #{failure[:reason]}")
        end
      end

      def build_results(duration)
        {
          successful: @success_count,
          failed: @failure_count,
          skipped: @skipped_count,
          overwritten: @overwritten_count,
          errors: [],
          duration: duration
        }
      end
    end
  end
end
