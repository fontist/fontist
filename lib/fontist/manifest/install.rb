require_relative "common"

module Fontist
  module Manifest
    class Install < Common
      def initialize(manifest, confirmation: "no")
        @manifest = manifest
        @confirmation = confirmation
      end

      def self.call(manifest, confirmation: "no")
        new(manifest, confirmation: confirmation).call
      end

      private

      def file_paths(font, style)
        paths = find_installed_font(font, style)
        return paths unless paths.empty?

        install_font(font)
        find_installed_font(font, style)
      end

      def find_installed_font(font, style)
        Fontist::SystemFont.find_with_style(font, style)
      end

      def install_font(font)
        Fontist::Font.try_install(font, confirmation: @confirmation)
      rescue Fontist::Errors::LicensingError
        [] # try to install other fonts
      end
    end
  end
end
