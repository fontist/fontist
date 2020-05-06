module Fontist
  module Formulas
    class Base
      def initialize(font_name, confirmation:, **options)
        @font_name = font_name
        @confirmation = confirmation || "no"
        @force_download = options.fetch(:force_download, false)
        @fonts_path = options.fetch(:fonts_path, Fontist.fonts_path)

        check_user_license_agreement
      end

      def self.fetch_font(font_name, confirmation: nil, **options)
        new(font_name, options.merge(confirmation: confirmation)).fetch
      end

      private

      attr_reader :font_name, :confirmation, :fonts_path, :force_download

      def check_user_license_agreement
      end
    end
  end
end
