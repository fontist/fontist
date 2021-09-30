require "plist"
require "nokogiri"
require "fontist/import"
require_relative "recursive_extraction"
require_relative "helpers/hash_helper"
require_relative "manual_formula_builder"

module Fontist
  module Import
    class Macos
      FONT_XML = "/System/Library/AssetsV2/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml".freeze # rubocop:disable Layout/LineLength
      DESCRIPTION = "Fonts included with macOS %<name>s".freeze

      INSTRUCTIONS = <<~INSTRUCTIONS.freeze
        To download and enable any of these fonts:

        1. Open Font Book, which is in your Applications folder.
        2. Select All Fonts in the sidebar, or use the Search field to find the font that you want to download. Fonts that are not already downloaded appear dimmed in the list of fonts.
        3. Select the dimmed font and choose Edit > Download, or Control-click it and choose Download from the pop-up menu.
      INSTRUCTIONS

      def initialize(options = {})
        @options = options
      end

      def call
        downloadable_fonts = fetch_fonts_list
        links = fetch_links(downloadable_fonts)
        archives = download(links)
        store_in_dir(archives) do |dir|
          create_formula(dir)
        end
      end

      private

      def fetch_fonts_list
        html = Net::HTTP.get(URI.parse(@options[:fonts_link]))

        document = Nokogiri::HTML.parse(html)
        document.css("#sections div.grid2col:nth-of-type(3) div ul > li",
                     "#sections div.grid2col:nth-of-type(4) div ul > li")
          .map(&:text)
      end

      def fetch_links(downloadable_fonts)
        data = Plist.parse_xml(FONT_XML)
        assets = downloadable_assets(data, downloadable_fonts)
        assets_links(assets)
      end

      def downloadable_assets(data, downloadable_fonts)
        data["Assets"].select do |x|
          x["FontInfo4"].any? do |i|
            downloadable_fonts.find do |d|
              d.start_with?(i["FontFamilyName"])
            end
          end
        end
      end

      def assets_links(assets)
        assets.map do |x|
          x.values_at("__BaseURL", "__RelativePath").join
        end
      end

      def download(links)
        links.map do |url|
          Fontist::Utils::Downloader.download(url, progress_bar: true).path
        end
      end

      def store_in_dir(archives)
        Dir.mktmpdir do |dir|
          archives.each do |archive|
            FileUtils.ln(archive, dir)
          end

          yield dir
        end
      end

      def create_formula(archives_dir)
        extractor = RecursiveExtraction.new(archives_dir)
        path = save(formula(archives_dir, extractor))
        Fontist.ui.success("Formula has been successfully created: #{path}")

        path
      end

      def formula(archive, extractor)
        builder = ManualFormulaBuilder.new
        setup_strings(builder, archive)
        setup_files(builder, extractor)
        builder.formula
      end

      def setup_strings(builder, archive)
        builder.url = archive
        builder.archive = archive
        builder.platforms = platforms
        builder.instructions = instructions
        builder.description = description
        builder.options = builder_options
      end

      def platforms
        major_version = Sys::Uname.release.split(".").first

        ["macos-#{major_version}"]
      end

      def instructions
        INSTRUCTIONS.strip
      end

      def description
        format(DESCRIPTION, name: @options[:name])
      end

      def builder_options
        @options.merge(homepage: @options[:fonts_link])
      end

      def setup_files(builder, extractor)
        builder.extractor = extractor
        builder.font_files = extractor.font_files
        builder.font_collection_files = extractor.font_collection_files
        builder.license_text = extractor.license_text
      end

      def save(hash)
        filename = Import.name_to_filename(@options[:name])
        path = File.join(formula_dir, filename)
        yaml = YAML.dump(Helpers::HashHelper.stringify_keys(hash))
        File.write(path, yaml)
        path
      end

      def formula_dir
        @formula_dir ||= Fontist.formulas_path.join("macos").tap do |path|
          FileUtils.mkdir_p(path) unless File.exist?(path)
        end
      end
    end
  end
end
