require "fontist/formulas/helpers/exe_extractor"

module Fontist
  module Formulas
    class FontFormula
      include Singleton
      extend Fontist::Formulas::Helpers::Dsl

      include Fontist::Formulas::Helpers::ExeExtractor
      attr_accessor :homepage, :description, :temp_resource, :licence

      def font_list
        @font_list ||= []
      end

      def resources
        @resources ||= {}
      end

      def fonts
        @fonts ||= font_list.uniq
      end

      def extract_font_styles(options)
        extract_from_file(options) ||
          extract_from_collection(options) || default_font
      end

      def reinitialize
        @downloaded = false
        @matched_fonts = []
      end

      def self.fetch_font(name, confirmation:)
        if instance.licence && confirmation.downcase != "yes"
          raise(Fontist::Errors::LicensingError)
        end

        instance.reinitialize
        instance.install_font(name, confirmation)
      end

      def install_font(name, confirmation)
        run_in_temp_dir { extract }
        matched_fonts_uniq = matched_fonts.flatten.uniq
        matched_fonts_uniq.empty? ? nil : matched_fonts_uniq
      end

      private

      attr_reader :downloaded, :matched_fonts

      def resource(name, &block)
        source = resources[name]
        block_given? ? yield(source) : source
      end

      def fonts_path
        @fonts_path ||= Fontist.fonts_path
      end

      def default_font
        [{ type: "Regular", font: temp_resource[:filename] }]
      end

      def run_in_temp_dir(&block)
        Dir.mktmpdir(nil, Dir.tmpdir) do |dir|
          @temp_dir = Pathname.new(dir)

          yield
          @temp_dir = nil
        end
      end

      def extract_from_file(options)
        styles = options.fetch(:match_styles_from_file, [])

        unless styles.empty?
          styles.map { |type, file | { type: type, font: file } }
        end
      end

      def match_fonts(fonts_dir, font_name)
        fonts = map_names_to_fonts(font_name).join("|")
        font = fonts_dir.grep(/#{fonts}/i)
        @matched_fonts.push(font) if font

        font
      end

      def extract_from_collection(options)
        styles = options.fetch(:extract_styles_from_collection, [])

        unless styles.empty?
          styles.map do |type, file|
            { type: type, collection: file, font: temp_resource[:filename] }
          end
        end
      end

      def map_names_to_fonts(font_name)
        fonts = FormulaFinder.find_fonts(font_name)
        fonts = fonts.map { |font| font.styles.map(&:font) }.flatten if fonts

        fonts || []
      end

      def download_file(source)
        downloaded_file = Fontist::Downloader.download(
          source[:urls].first, sha: source[:sha256], file_size: source[:file_size]
        )

        @downloaded = true
        downloaded_file
      end
    end
  end
end
