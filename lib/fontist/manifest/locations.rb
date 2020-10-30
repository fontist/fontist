require_relative "common"

module Fontist
  module Manifest
    class Locations < Common
      private

      def file_paths(font, style)
        Fontist::SystemFont.find_with_style(font, style)
      end
    end
  end
end
