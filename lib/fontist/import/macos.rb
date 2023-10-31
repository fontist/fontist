require "plist"
require "nokogiri"
require "fontist/import/create_formula"

module Fontist
  module Import
    class Macos
      FONT_XML = "/System/Library/AssetsV2/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml".freeze # rubocop:disable Layout/LineLength
      HOMEPAGE = "https://support.apple.com/en-om/HT211240#document".freeze

      def initialize(font_xml = FONT_XML)
        @font_xml = font_xml
      end

      def call
        links.each do |link|
          create_formula(link)
        end

        Fontist::Index.rebuild

        Fontist.ui.success("Created #{links.size} formulas.")
      end

      private

      def links
        data = Plist.parse_xml(@font_xml)
        data["Assets"].map do |x|
          x.values_at("__BaseURL", "__RelativePath").join
        end
      end

      def create_formula(url)
        path = Fontist::Import::CreateFormula.new(
          url,
          platforms: platforms,
          homepage: homepage,
          requires_license_agreement: license,
          formula_dir: formula_dir,
          keep_existing: true,
        ).call
        Fontist.ui.success("Formula has been successfully created: #{path}")

        path
      end

      def platforms
        ["macos"]
      end

      def homepage
        HOMEPAGE
      end

      def license
        @license ||= File.read(File.expand_path("macos/macos_license.txt",
                                                __dir__))
      end

      def formula_dir
        @formula_dir ||= Fontist.formulas_path.join("macos").tap do |path|
          FileUtils.mkdir_p(path) unless File.exist?(path)
        end
      end
    end
  end
end
