require_relative "locations"

module Fontist
  module Manifest
    class Install < Locations
      def initialize(manifest, confirmation: "no", hide_licenses: false)
        @manifest = manifest
        @confirmation = confirmation
        @hide_licenses = hide_licenses
      end

      private

      def file_paths(font, style)
        paths = find_font_with_name(font, style)
        return paths unless paths["paths"].empty?

        install_font(font)

        find_font_with_name(font, style)
      end

      def install_font(font)
        Fontist::Font.install(font, force: true, confirmation: @confirmation, hide_licenses: @hide_licenses)
      end
    end
  end
end
