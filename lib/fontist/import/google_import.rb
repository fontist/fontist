require_relative "google"
require_relative "google/api"
require_relative "google/create_google_formula"

module Fontist
  module Import
    class GoogleImport
      REPO_PATH = Fontist.fontist_path.join("google", "fonts")
      REPO_URL = "https://github.com/google/fonts.git".freeze

      def initialize(options)
        @max_count = options[:max_count] || Google::DEFAULT_MAX_COUNT
      end

      def call
        update_repo
        count = update_formulas
        rebuild_index if count.positive?
      end

      private

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
    end
  end
end
