module Fontist
  module Formulas
    class KulimParkFont < FontFormula
      FULLNAME = "Kulim Park".freeze
      CLEANNAME = "KulimPark".freeze

      desc FULLNAME
      homepage "http://http:noponies.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Kulim%20Park"
        sha256 "5b7ad09b315b9e5e871c962d5880e5b6cb829c4a207b4222fcc9067a4c7f143c"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "ExtraLight" => "KulimPark-ExtraLight.ttf",
        "ExtraLightItalic" => "KulimPark-ExtraLightItalic.ttf",
        "Light" => "KulimPark-Light.ttf",
        "LightItalic" => "KulimPark-LightItalic.ttf",
        "Regular" => "KulimPark-Regular.ttf",
        "Italic" => "KulimPark-Italic.ttf",
        "SemiBold" => "KulimPark-SemiBold.ttf",
        "SemiBoldItalic" => "KulimPark-SemiBoldItalic.ttf",
        "Bold" => "KulimPark-Bold.ttf",
        "BoldItalic" => "KulimPark-BoldItalic.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/KulimPark-ExtraLight.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/KulimPark-ExtraLight.ttf", :exist?
        end
      end

      copyright "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
