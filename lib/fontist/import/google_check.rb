require_relative "google/new_fonts_fetcher"

module Fontist
  module Import
    class GoogleCheck
      def call
        fetch_formulas
        fonts = new_fonts
        indicate(fonts)
      end

      private

      def fetch_formulas
        Formula.update_formulas_repo
      end

      def new_fonts
        Fontist::Import::Google::NewFontsFetcher.new(logging: true).call
      end

      def indicate(new_paths)
        return if new_paths.empty?

        puts "New fonts are available in:"
        new_paths.each do |path|
          puts path
        end

        abort
      end
    end
  end
end
