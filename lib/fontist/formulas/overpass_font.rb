module Fontist
  module Formulas
    class OverpassFont < FontFormula
      desc "Overpass Font"
      homepage "http://overpassfont.org"

      resource "overpass.zip" do
        url "https://github.com/RedHatOfficial/Overpass/releases/download/3.0.2/overpass-desktop-fonts.zip"
        sha256 "10d2186ad1e1e628122f2e4ea0bbde16438e34a0068c35190d41626d89bb64e4"
      end

      provides_font(
        "Overpass",
        match_styles_from_file: [
          {
            family_name: "Overpass",
            style: "Bold Italic",
            full_name: "Overpass Bold Italic",
            post_script_name: "Overpass-BoldItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-bold-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Bold",
            full_name: "Overpass Bold",
            post_script_name: "Overpass-Bold",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-bold.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "ExtraBold Italic",
            full_name: "Overpass ExtraBold Italic",
            post_script_name: "Overpass-ExtraBoldItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-extrabold-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "ExtraBold",
            full_name: "Overpass ExtraBold",
            post_script_name: "Overpass-ExtraBold",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-extrabold.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "ExtraLight",
            full_name: "Overpass ExtraLight",
            post_script_name: "Overpass-ExtraLight",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-extralight.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "ExtraLight Italic",
            full_name: "Overpass ExtraLight Italic",
            post_script_name: "Overpass-ExtraLightItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-extralight-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Heavy Italic",
            full_name: "Overpass Heavy Italic",
            post_script_name: "Overpass-HeavyItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-heavy-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Heavy",
            full_name: "Overpass Heavy",
            post_script_name: "Overpass-Heavy",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-heavy.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Italic",
            full_name: "Overpass Italic",
            post_script_name: "Overpass-Italic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Light Italic",
            full_name: "Overpass Light Italic",
            post_script_name: "Overpass-LightItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-light-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Light",
            full_name: "Overpass Light",
            post_script_name: "Overpass-Light",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-light.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Regular",
            full_name: "Overpass Regular",
            post_script_name: "Overpass-Regular",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-regular.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "SemiBold Italic",
            full_name: "Overpass SemiBold Italic",
            post_script_name: "Overpass-SemiBoldItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-semibold-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "SemiBold",
            full_name: "Overpass SemiBold",
            post_script_name: "Overpass-SemiBold",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-semibold.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Thin Italic",
            full_name: "Overpass Thin Italic",
            post_script_name: "Overpass-ThinItalic",
            version: "3.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-thin-italic.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass",
            style: "Thin",
            full_name: "Overpass Thin",
            post_script_name: "Overpass-Thin",
            version: "3.000;DELV;Overpass",
            description: "Copyright (c) 2011-2016 by Red Hat, Inc. All rights reserved.",
            filename: "overpass-thin.otf",
            copyright: "Copyright © 2016 by Red Hat, Inc. All rights reserved.",
          },
        ]
      )

      provides_font(
        "Overpass Mono",
        match_styles_from_file: [
          {
            family_name: "Overpass Mono",
            style: "Bold",
            full_name: "Overpass Mono Bold",
            post_script_name: "OverpassMono-Bold",
            version: "1.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-mono-bold.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass Mono",
            style: "Regular",
            full_name: "Overpass Mono Regular",
            post_script_name: "OverpassMono-Regular",
            version: "1.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-mono-regular.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass Mono",
            style: "Light",
            full_name: "Overpass Mono Light",
            post_script_name: "OverpassMono-Light",
            version: "1.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-mono-light.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
          {
            family_name: "Overpass Mono",
            style: "SemiBold",
            full_name: "Overpass Mono SemiBold",
            post_script_name: "OverpassMono-SemiBold",
            version: "1.000;DELV;Overpass",
            description: "Overpass is an open source webfont family inspired by Highway Gothic. Sponsored by Red Hat and created by Delve Fonts.",
            filename: "overpass-mono-semibold.otf",
            copyright: "Copyright (c) 2016 by Red Hat, Inc. All rights reserved.",
          },
        ]
      )

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
