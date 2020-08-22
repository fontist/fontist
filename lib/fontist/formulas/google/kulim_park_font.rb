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

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Kulim Park",
            style: "ExtraLight",
            full_name: "Kulim Park ExtraLight",
            post_script_name: "KulimPark-ExtraLight",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-ExtraLight.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "ExtraLight Italic",
            full_name: "Kulim Park ExtraLight Italic",
            post_script_name: "KulimPark-ExtraLightItalic",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-ExtraLightItalic.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "Light",
            full_name: "Kulim Park Light",
            post_script_name: "KulimPark-Light",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-Light.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "Light Italic",
            full_name: "Kulim Park Light Italic",
            post_script_name: "KulimPark-LightItalic",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-LightItalic.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "Regular",
            full_name: "Kulim Park Regular",
            post_script_name: "KulimPark-Regular",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-Regular.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "Italic",
            full_name: "Kulim Park Italic",
            post_script_name: "KulimPark-Italic",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-Italic.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "SemiBold",
            full_name: "Kulim Park SemiBold",
            post_script_name: "KulimPark-SemiBold",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-SemiBold.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "SemiBold Italic",
            full_name: "Kulim Park SemiBold Italic",
            post_script_name: "KulimPark-SemiBoldItalic",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-SemiBoldItalic.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "Bold",
            full_name: "Kulim Park Bold",
            post_script_name: "KulimPark-Bold",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-Bold.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
          {
            family_name: "Kulim Park",
            style: "Bold Italic",
            full_name: "Kulim Park Bold Italic",
            post_script_name: "KulimPark-BoldItalic",
            version: "1.000; ttfautohint (v1.8.3)",
            filename: "KulimPark-BoldItalic.ttf",
            copyright: "Copyright 2018 The Kulim Park Project Authors (https://github.com/noponies/Kulim-Park)",
          },
        ]
      )

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
