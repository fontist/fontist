module Fontist
  module Formulas
    class OverpassFont < FontFormula
      desc "Overpass Font"
      homepage "http://overpassfont.org"

      resource "overpass.zip" do
        url "https://github.com/RedHatOfficial/Overpass/releases/download/3.0.2/overpass-desktop-fonts.zip"
        sha256 "10d2186ad1e1e628122f2e4ea0bbde16438e34a0068c35190d41626d89bb64e4"
      end

      provides_font("Overpass", match_styles_from_file: {
        "Bold Italic" => "overpass-bold-italic.otf",
        "Bold" => "overpass-bold.otf",
        "Extrabold Italic" => "overpass-extrabold-italic.otf",
        "Extrabold" => "overpass-extrabold.otf",
        "Extralight" => "overpass-extralight.otf",
        "Extralight Italic" => "overpass-extralight-italic.otf",
        "Heavy Italic" => "overpass-heavy-italic.otf",
        "Heavy" => "overpass-heavy.otf",
        "Italic" => "overpass-italic.otf",
        "Light Italic" => "overpass-light-italic.otf",
        "Light" => "overpass-light.otf",
        "Regular" => "overpass-regular.otf",
        "Semibold Italic" => "overpass-semibold-italic.otf",
        "Semibold" => "overpass-semibold.otf",
        "Thin Italic" => "overpass-thin-italic.otf",
        "Thin" => "overpass-thin.otf"
      })

      provides_font("Overpass Mono", match_styles_from_file: {
        "Bold" => "overpass-mono-bold.otf",
        "Regular" => "overpass-mono-regular.otf",
        "Light" => "overpass-mono-light.otf",
        "Semibold" => "overpass-mono-semibold.otf"
      })

      def extract
        resource("overpass.zip") do |resource|
          unzip(resource, fonts_sub_dir: "overpass**/") do |fontdir|
            match_fonts(fontdir, "Overpass")
            match_fonts(fontdir, "Overpass Mono")
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/Overpass"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/overpass"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/Overpass/overpass-thin.otf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/overpass/overpass-thin.otf", :exist?
        end
      end

      open_license <<~EOS
  Copyright 2016 Red Hat, Inc.,

  This Font Software is dual licensed under the SIL Open Font License and the GNU Lesser General Public License, LGPL 2.1 : http://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html OFL 1.1 : http://scripts.sil.org/OFL

      EOS
    end
  end
end
