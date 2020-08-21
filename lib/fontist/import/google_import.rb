require "erb"
require_relative "google/fonts_public.pb"
require_relative "template_helper"
require_relative "text_helper"
require_relative "otf_parser"
require_relative "otf_style"

module Fontist
  module Import
    class GoogleImport
      REPO_PATH = Fontist.root_path.join("tmp", "fonts")
      TEMPLATE_PATH = File.expand_path("google/template.erb", __dir__)
      SKIPLIST_PATH = File.expand_path("google/skiplist.yml", __dir__)
      SHA256_REGEXP = /sha256 "(.*)"/.freeze
      SHA256_COMMENT = %(# sha256 "" # file changes between downloads).freeze

      def call
        fonts_paths = fetch_fonts_paths.sort
        fonts_paths.each do |path|
          create_formula(path)
        end

        puts "Updating SHA256..."
        fonts_paths.each do |path|
          update_sha256(path)
        end
      end

      private

      def fetch_fonts_paths
        Dir[File.join(REPO_PATH, "apache", "*"),
            File.join(REPO_PATH, "ofl", "*"),
            File.join(REPO_PATH, "ufl", "*")]
      end

      def create_formula(path)
        print "#{path}, "
        metadata = fetch_metadata(path)
        return puts("skipped, no metadata") unless metadata

        available = check_font(metadata)
        return unless available

        font = fetch_font(metadata, path)
        code = render_code(font)
        save_formula(code, font)
        check_formula(font)
        puts "saved"
      end

      def fetch_metadata(path)
        metadata_path = File.join(path, "METADATA.pb")
        return unless File.exists?(metadata_path)

        # Protobuf file could be downloaded from
        # https://raw.githubusercontent.com/googlefonts/gftools/master/Lib/gftools/fonts_public.proto
        #
        # To compile Protobuf to Ruby use
        # $ ruby-protoc lib/fontist/import/google/fonts_public.proto
        Google::Fonts::FamilyProto.parse_from_text(File.read(metadata_path))
      end

      def check_font(metadata)
        return puts("skipped, overriden") if in_skiplist?(metadata.name)
        return puts("exists") if formula_exists?(metadata.name)
        return puts("skipped, no download") unless downloadable?(metadata.name)

        true
      end

      def in_skiplist?(name)
        @skiplist ||= YAML.safe_load(File.open(SKIPLIST_PATH))
        @skiplist.include?(name)
      end

      def formula_exists?(name)
        File.exist?(Fontist.formulas_path.join("google", formula_file(name)))
      end

      def formula_file(name)
        name.downcase.gsub(" ", "_") + "_font.rb"
      end

      def downloadable?(name)
        Down.open("https://fonts.google.com/download?family=#{name}")
        true
      rescue Down::NotFound
        false
      end

      def fetch_font(metadata, path)
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

      def save_formula(code, font)
        path = formula_path(font.fullname)
        File.write(path, code)
        path
      end

      def formula_path(name)
        file_name = name.downcase.gsub(" ", "_") + "_font.rb"
        Fontist.formulas_path.join("google", file_name)
      end

      def check_formula(font)
        require formula_path(font.fullname)
      end

      def update_sha256(path)
        print "#{path}, "
        fixed = fix_sha256(path)
        puts(fixed ? "overwritten" : "skipped")
      end

      def fix_sha256(path)
        metadata = fetch_metadata(path)
        return unless metadata

        code = read_code(metadata.name)
        return unless code

        previous = fetch_sha256(code)
        return if previous.empty?

        new = sha256(metadata.name)
        return if previous == new

        comment_out_sha256(metadata.name, code)
        true
      end

      def read_code(name)
        formula_path = formula_path(name)
        return unless File.exists?(formula_path)

        File.read(formula_path)
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
