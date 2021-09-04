require "erb"
require_relative "google"
require_relative "google/new_fonts_fetcher"
require_relative "create_formula"

module Fontist
  module Import
    class GoogleImport
      def call
        fonts = new_fonts
        create_formulas(fonts)
        rebuild_index
      end

      private

      def new_fonts
        Fontist::Import::Google::NewFontsFetcher.new(logging: true).call
      end

      def create_formulas(fonts)
        return puts("Nothing to update") if fonts.empty?

        puts "Creating formulas..."
        fonts.each do |path|
          create_formula(path)
        end
      end

      def create_formula(font_path)
        puts font_path

        path = Fontist::Import::CreateFormula.new(
          url(font_path),
          name: Google.metadata_name(font_path),
          formula_dir: formula_dir,
          skip_sha: variable_style?(font_path),
          digest: Google.digest(font_path),
        ).call

        Fontist.ui.success("Formula has been successfully created: #{path}")
      end

      def url(path)
        name = Google.metadata_name(path)
        "https://fonts.google.com/download?family=#{ERB::Util.url_encode(name)}"
      end

      def formula_dir
        @formula_dir ||= Fontist.formulas_path.join("google").tap do |path|
          FileUtils.mkdir_p(path) unless File.exist?(path)
        end
      end

      def variable_style?(path)
        fonts = Dir.glob(File.join(path, "*.{ttf,otf}"))
        fonts.any? do |font|
          File.basename(font).match?(/\[(.+,)?(wght|opsz)\]/)
        end
      end

      def rebuild_index
        Fontist::Index.rebuild
      end
    end
  end
end
