require "zip"

module Fontist
  module Formulas
    class SourceFont < Formulas::Base
      include Formulas::Helpers::ZipExtractor

      private

      def data_node
        @data_node ||= "source_font"
      end

      def extract_fonts(font_names)
        resources(data_node) do |resource|
          zip_extract(resource, fonts_sub_dir: "fonts/") do |fonts_paths|
            font_names.each do |font_name|
              match_fonts(fonts_paths, font_name)
            end
          end
        end
      end
    end
  end
end
