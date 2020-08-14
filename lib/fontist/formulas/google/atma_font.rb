module Fontist
  module Formulas
    class AtmaFont < FontFormula
      FULLNAME = "Atma".freeze
      CLEANNAME = "Atma".freeze

      desc FULLNAME
      homepage "www.black-foundry.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Atma"
        sha256 "e57b5218c3ebb43f6e481a3cc83105af52c5851077dd2eff8dd52a9761a10499"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Light" => "Atma-Light.ttf",
        "Regular" => "Atma-Regular.ttf",
        "Medium" => "Atma-Medium.ttf",
        "SemiBold" => "Atma-SemiBold.ttf",
        "Bold" => "Atma-Bold.ttf",
      })

      def extract
        resource("#{CLEANNAME}.zip") do |resource|
          zip_extract(resource) do |fontdir|
            match_fonts(fontdir, FULLNAME)
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/#{CLEANNAME}"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/#{CLEANNAME.downcase}"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Atma-Light.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Atma-Light.ttf", :exist?
        end
      end

      copyright "Copyright 2015 The Atma Project Authors (www.black-foundry.com)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
