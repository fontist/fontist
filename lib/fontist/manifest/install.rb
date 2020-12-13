require_relative "locations"

module Fontist
  module Manifest
    class Install < Locations
      def initialize(manifest, confirmation: "no")
        @manifest = manifest
        @confirmation = confirmation
      end

      private

      def file_paths(font, style)
        paths = find_font_with_name(font, style)
        return paths unless paths["paths"].empty?

        install_font(font)

        find_font_with_name(font, style)
      end

      def install_font(font)
        Fontist::Font.install(font, force: true, confirmation: @confirmation)
      end
    end
  end
end
