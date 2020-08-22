module Fontist
  module Formulas
    class BlinkerFont < FontFormula
      FULLNAME = "Blinker".freeze
      CLEANNAME = "Blinker".freeze

      desc FULLNAME
      homepage "http://supertype.de"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Blinker"
        sha256 "464cf9c409438069e5093cef6c268a2e614ef205f7578ed0a8a504bf1b61e2f9"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Blinker",
            style: "Thin",
            full_name: "Blinker Thin",
            post_script_name: "Blinker-Thin",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-Thin.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "ExtraLight",
            full_name: "Blinker ExtraLight",
            post_script_name: "Blinker-ExtraLight",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-ExtraLight.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "Light",
            full_name: "Blinker Light",
            post_script_name: "Blinker-Light",
            version: "1.016;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-Light.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "Regular",
            full_name: "Blinker",
            post_script_name: "Blinker-Regular",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-Regular.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "SemiBold",
            full_name: "Blinker SemiBold",
            post_script_name: "Blinker-SemiBold",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-SemiBold.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "Bold",
            full_name: "Blinker Bold",
            post_script_name: "Blinker-Bold",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-Bold.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "ExtraBold",
            full_name: "Blinker ExtraBold",
            post_script_name: "Blinker-ExtraBold",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-ExtraBold.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
          },
          {
            family_name: "Blinker",
            style: "Black",
            full_name: "Blinker Black",
            post_script_name: "Blinker-Black",
            version: "1.015;PS 1.15;hotconv 1.0.88;makeotf.lib2.5.647800",
            filename: "Blinker-Black.ttf",
            copyright: "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Blinker-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Blinker-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
