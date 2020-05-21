module Fontist
  module Formulas
    class CourierFont < Base
      include Formulas::Helpers::ExeExtractor

      private

      def extract_fonts(font_names)
        resources("courier") do |resource|
          cab_extract(resource) do |fonts_dir|
            font_names.each do |font_name|
              match_fonts(fonts_dir, font_name)
            end
          end
        end
      end

      def check_user_license_agreement
        unless resources("courier").agreement === confirmation
          raise(Fontist::Errors::LicensingError)
        end
      end
    end
  end
end
