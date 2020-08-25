require "erb"
require_relative "google"
require_relative "google/new_fonts_fetcher"
require_relative "google/fonts_public.pb"
require_relative "template_helper"
require_relative "text_helper"
require_relative "otf_parser"
require_relative "otf_style"

module Fontist
  module Import
    class GoogleImport
      TEMPLATE_PATH = File.expand_path("google/template.erb", __dir__)
      SHA256_REGEXP = /sha256 "(.*)"/.freeze
      SHA256_COMMENT = %(# sha256 "" # file changes between downloads).freeze

      def call
        fonts = new_fonts
        create_formulas(fonts)
        update_formulas(fonts)
      end

      private

      def new_fonts
        Fontist::Import::Google::NewFontsFetcher.new.call
      end

      def create_formulas(fonts)
        fonts.each do |path|
          create_formula(path)
        end
      end

      def create_formula(path)
        puts path
        metadata = fetch_metadata(path)
        font = build_font(metadata, path)
        code = render_code(font)
        path = formula_path(font.fullname)
        save_formula(code, path)
        check_formula(path)
      end

      def fetch_metadata(path)
        protobuf = File.read(File.join(path, "METADATA.pb"))
        ::Google::Fonts::FamilyProto.parse_from_text(protobuf)
      end

      def build_font(metadata, path)
        h = from_metadata(metadata)
          .merge(from_otfinfo(path))
          .merge(styles: styles_from_otfinfo(path, metadata.fonts))
          .merge(from_license(path))

        OpenStruct.new(h)
      end

      def from_metadata(metadata)
        copyright = metadata.fonts.first.copyright

        { fullname: metadata.name,
          cleanname: metadata.name.gsub(/ /, ""),
          sha256: sha256(metadata.name),
          copyright: Fontist::Import::TextHelper.cleanup(copyright) }
      end

      def sha256(name)
        file = Down.download("https://fonts.google.com/download?family=#{name}",
                             open_timeout: 10,
                             read_timeout: 10)

        Digest::SHA256.file(file).to_s
      end

      def from_license(path)
        file = Dir.glob(File.join(path, "{OFL.txt,UFL.txt,LICENSE.txt}")).first
        print "warn, no license, " unless file
        return { license: "" } unless file

        license = File.read(file)
          .rstrip
          .gsub("\r\n", "\n")
          .lines
          .drop_while { |line| line.strip.empty? }
          .join

        { license: license }
      end

      def from_otfinfo(path)
        font_file = Dir.glob(File.join(path, "*.ttf")).first
        otf = OtfParser.new(font_file).call

        { homepage: otf["Vendor URL"],
          license_url: otf["License URL"] }
      end

      def styles_from_otfinfo(path, fonts)
        fonts.map do |f|
          file_path = File.join(path, f.filename)
          info = OtfParser.new(file_path).call
          OtfStyle.new(info, file_path).call
        end
      end

      def render_code(font)
        template = File.read(TEMPLATE_PATH)
        renderer = ERB.new(template, trim_mode: "-")
        renderer.result(Fontist::Import::TemplateHelper.bind(font, "font"))
      end

      def formula_path(name)
        Fontist::Import::Google.formula_path(name)
      end

      def save_formula(code, path)
        File.write(path, code)
      end

      def check_formula(path)
        require path
      end

      def update_formulas(fonts)
        puts "Updating SHA256..."
        fonts.each do |path|
          update_sha256(path)
        end
      end

      def update_sha256(path)
        print "#{path}, "
        fixed = fix_sha256(path)
        puts(fixed ? "overwritten" : "skipped")
      end

      def fix_sha256(path)
        metadata = fetch_metadata(path)
        code = read_code(metadata.name)
        previous = fetch_sha256(code)
        return if previous.empty?

        new = sha256(metadata.name)
        return if previous == new

        comment_out_sha256(metadata.name, code)
        true
      end

      def read_code(name)
        File.read(formula_path(name))
      end

      def fetch_sha256(code)
        code.match(SHA256_REGEXP)[1]
      end

      def comment_out_sha256(name, code)
        code.sub!(SHA256_REGEXP, SHA256_COMMENT)
        File.write(formula_path(name), code)
      end
    end
  end
end
