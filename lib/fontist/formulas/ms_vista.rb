module Fontist
  module Formulas
    class MsVista < Base
      include Formulas::Helpers::ExeExtractor

      private

      def data_node
        @data_node ||= "msvista"
      end

      def check_user_license_agreement
        unless resources(data_node).agreement === confirmation
          raise(Fontist::Errors::LicensingError)
        end
      end

      def extract_fonts(font_names)
        resources(data_node) do |resource|
          exe_extract(resource) do |cab_file|
            cab_extract(cab_file, download: false) do |fonts_dir|
              font_names.each do |font_name|
                match_fonts(fonts_dir, font_name)
              end
            end
          end
        end
      end

      def exe_extract(source)
        cab_files = decompressor.search(download_file(source).path)
        decompressor.extract(cab_files.files.next, ppviewer_cab)

        yield(ppviewer_cab) if block_given?
      end

      def ppviewer_cab
        @ppviewer_cab ||= Fontist.assets_path.join("ppviewer.cab").to_s
      end
    end
  end
end
