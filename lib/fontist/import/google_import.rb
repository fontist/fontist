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
      def call
        fonts = new_fonts
        create_formulas(fonts)
      end

      private

      def new_fonts
        Fontist::Import::Google::NewFontsFetcher.new(logging: true).call
      end

      def create_formulas(fonts)
        puts "Creating formulas..."
        fonts.each do |path|
          create_formula(path)
        end
      end

      def create_formula(path)
        puts path
        metadata = fetch_metadata(path)
        font = build_font(metadata, path)
        save_formula(font)
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

        Hash.new.tap do |h|
          h[:fullname] = metadata.name
          h[:cleanname] = metadata.name.gsub(/ /, "")
          h[:sha256] = sha256(metadata.name) unless variable_style?(metadata)
          h[:copyright] = Fontist::Import::TextHelper.cleanup(copyright)
        end
      end

      def variable_style?(metadata)
        metadata.fonts.any? do |s|
          s.filename.match?(/\[(.+,)?wght\]/)
        end
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

        { license: cleanup_text(File.read(file)) }
      end

      def cleanup_text(text)
        text.rstrip
          .gsub("\r\n", "\n")
          .lines
          .map(&:rstrip)
          .drop_while(&:empty?)
          .join("\n")
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

      def save_formula(font)
        hash = formula_hash(font)
        path = formula_path(font.fullname)
        save_to_path(hash, path)
      end

      def formula_hash(font)
        stringify_keys(name: font.cleanname.sub(/\S/, &:upcase),
                       description: font.fullname,
                       homepage: font.homepage,
                       resources: formula_resource(font),
                       fonts: [yaml_font(font)],
                       extract: { format: :zip },
                       copyright: font.copyright,
                       license_url: font.license_url,
                       open_license: font.license)
      end

      def stringify_keys(hash)
        JSON.parse(hash.to_json)
      end

      def formula_resource(font)
        encoded_name = ERB::Util.url_encode(font.fullname)
        url = "https://fonts.google.com/download?family=#{encoded_name}"

        options = {}
        options[:urls] = [url]
        options[:sha256] = font.sha256 if font.sha256

        { "#{font.cleanname}.zip" => options }
      end

      def yaml_font(font)
        { name: font.fullname,
          styles: yaml_styles(font.styles) }
      end

      def yaml_styles(styles)
        styles.map do |s|
          yaml_style(s)
        end
      end

      def yaml_style(style)
        Hash.new.tap do |h|
          h.merge!(family_name: style.family_name,
                   type: style.style,
                   full_name: style.full_name)
          h.merge!(style.to_h.select { |k, _|
            %i(post_script_name version description copyright).include?(k)
          }.compact)
          h.merge!(font: fix_variable_filename(style.filename))
        end
      end

      def fix_variable_filename(filename)
        filename.sub("[wght]", "-VariableFont_wght")
      end

      def formula_path(name)
        Fontist::Import::Google.formula_path(name)
      end

      def save_to_path(hash, path)
        File.write(path, YAML.dump(hash))
      end
    end
  end
end
