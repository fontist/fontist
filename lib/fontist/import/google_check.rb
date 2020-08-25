require_relative "google/new_fonts_fetcher"

module Fontist
  module Import
    class GoogleCheck
      def call
        fonts = new_fonts
        indicate(fonts)
      end

      private

      def new_fonts
        Fontist::Import::Google::NewFontsFetcher.new.call
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
