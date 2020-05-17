module Fontist
  module Formulas
    class MsSystem < Base
      private

      def data_node
        @data_node ||= "ms_system"
      end

      def check_user_license_agreement
        unless resources(data_node).agreement === confirmation
          raise(Fontist::Errors::LicensingError)
        end
      end

      def extract_fonts(font_names)
        resources(data_node) do |resource|
          cab_extract(resource) do |fonts_dir|
            font_names.each do |font_name|
              match_fonts(fonts_dir, font_name)
            end
          end
        end
      end
    end
  end
end
