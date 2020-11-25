require_relative "locations"

module Fontist
  module Manifest
    class Install < Locations
      def initialize(manifest, confirmation: "no")
        @manifest = manifest
        @confirmation = confirmation
      end

      def self.call(manifest, confirmation: "no")
        new(manifest, confirmation: confirmation).call
      end

      private

      def file_paths(font, style)
        paths = super
        return paths unless paths["paths"].empty?

        install_font(font)
        super
      end

      def install_font(font)
        Fontist::Font.try_install(font, confirmation: @confirmation)
      rescue Fontist::Errors::LicensingError
        [] # try to install other fonts
      end
    end
  end
end
