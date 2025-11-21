# DEPRECATED: This class is deprecated and will be removed in a future version.
# Please use Fontist::Import::GoogleImporter instead, which provides access
# to the new architecture with improved performance, error handling, and features.
#
# @deprecated Use {Fontist::Import::GoogleImporter} instead
# @see Fontist::Import::GoogleImporter

require_relative "google"
require_relative "google/api"
require_relative "google/create_google_formula"

module Fontist
  module Import
    # Legacy Google Fonts import class
    #
    # @deprecated This class is deprecated and maintained only for backward compatibility.
    #   Use {GoogleImporter} instead which provides:
    #   - Better error handling and retry logic
    #   - Parallel processing support
    #   - Configuration-driven customization
    #   - Progress reporting
    #   - Comprehensive logging
    #
    # @example Migration to new system
    #   # Old way (deprecated)
    #   GoogleImport.new(max_count: 10).call
    #
    #   # New way (recommended)
    #   GoogleImporter.new(max_count: 10).import
    class GoogleImport
      REPO_PATH = Fontist.fontist_path.join("google", "fonts")
      REPO_URL = "https://github.com/google/fonts.git".freeze

      # @deprecated Use {GoogleImporter#new} instead
      def initialize(options)
        warn_deprecation
        @max_count = options[:max_count] || Google::DEFAULT_MAX_COUNT
        @options = options
      end

      # @deprecated Use {GoogleImporter#import} instead
      def call
        warn_deprecation

        # For backward compatibility, delegate to new GoogleImporter
        if use_new_importer?
          delegate_to_new_importer
        else
          legacy_import
        end
      end

      private

      # Checks if new importer should be used
      #
      # @return [Boolean] true if new importer is available and should be used
      def use_new_importer?
        # Check if new importer is available
        require_relative "google_importer"
        true
      rescue LoadError
        false
      end

      # Delegates to new GoogleImporter
      #
      # @return [void]
      def delegate_to_new_importer
        Fontist.ui.say("Using new Google Fonts import system...", :green)

        importer = Fontist::Import::GoogleImporter.new(@options)
        result = importer.import

        if result[:success]
          Fontist.ui.success("Import completed successfully")
          Fontist.ui.say("  Successful: #{result[:successful]}")
          Fontist.ui.say("  Failed: #{result[:failed]}") if result[:failed]&.positive?
        else
          Fontist.ui.error("Import failed: #{result[:error]}")
        end
      rescue StandardError => e
        Fontist.ui.error("New importer failed, falling back to legacy: #{e.message}")
        legacy_import
      end

      # Legacy import implementation (original code)
      #
      # @return [void]
      def legacy_import
        update_repo
        count = update_formulas
        rebuild_index if count.positive?
      end

      def update_repo
        if Dir.exist?(REPO_PATH)
          `cd #{REPO_PATH} && git pull`
        else
          FileUtils.mkdir_p(File.dirname(REPO_PATH))
          `git clone --depth 1 #{REPO_URL} #{REPO_PATH}`
        end
      end

      def update_formulas
        Fontist.ui.say "Updating formulas..."

        items = api_items

        count = 0
        items.each do |item|
          break if count >= @max_count

          path = update_formula(item)
          count += 1 if path
        end

        count
      end

      def api_items
        Google::Api.items
      end

      def update_formula(item)
        family = item["family"]
        Fontist.ui.say "Checking #{family}"
        unless new_changes?(item)
          Fontist.ui.say "Skip, no changes"
          return
        end

        create_formula(item)
      end

      def new_changes?(item)
        formula = formula(item["family"])
        return true unless formula

        item["files"].values != formula.resources.first.files
      end

      def formula(font_name)
        path = formula_path(font_name)
        Formula.from_file(path) if File.exist?(path)
      end

      def formula_path(name)
        snake_case = name.downcase.gsub(" ", "_")
        filename = "#{snake_case}.yml"
        Fontist.formulas_path.join("google", filename)
      end

      def create_formula(item)
        path = Google::CreateGoogleFormula.new(
          item,
          formula_dir: formula_dir,
        ).call

        Fontist.ui.success("Formula has been successfully created: #{path}")

        path
      end

      def formula_dir
        @formula_dir ||= Fontist.formulas_path.join("google").tap do |path|
          FileUtils.mkdir_p(path)
        end
      end

      def rebuild_index
        Fontist::Index.rebuild
      end

      # Prints deprecation warning
      #
      # @return [void]
      def warn_deprecation
        return if @deprecation_warned

        Fontist.ui.say("=" * 80, :yellow)
        Fontist.ui.say("DEPRECATION WARNING:", :yellow)
        Fontist.ui.say("Fontist::Import::GoogleImport is deprecated and will be removed in a future version.", :yellow)
        Fontist.ui.say("Please use Fontist::Import::GoogleImporter instead.", :yellow)
        Fontist.ui.say("", :yellow)
        Fontist.ui.say("Migration:", :yellow)
        Fontist.ui.say("  Old: GoogleImport.new(max_count: 10).call", :yellow)
        Fontist.ui.say("  New: GoogleImporter.new(max_count: 10).import", :yellow)
        Fontist.ui.say("", :yellow)
        Fontist.ui.say("The new importer provides better error handling, parallel processing,", :yellow)
        Fontist.ui.say("configuration-driven customization, and comprehensive logging.", :yellow)
        Fontist.ui.say("=" * 80, :yellow)
        Fontist.ui.say("")

        @deprecation_warned = true
      end
    end
  end
end
