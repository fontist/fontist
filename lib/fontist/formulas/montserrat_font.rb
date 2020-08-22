module Fontist
  module Formulas
    class MontserratFont < FontFormula
      desc "Montserrat Font"
      homepage "https://github.com/JulietaUla/Montserrat"

      resource "montserrat.zip" do
        url "https://www.fontsquirrel.com/fonts/download/montserrat"

        # Same issue here
        # sha256 "ea1d3721cba61e4de81f4425dee191c904e44129c07d825082d70ee4e168c437"
      end

      provides_font(
        "Montserrat",
        match_styles_from_file: [
          {
            family_name: "Montserrat",
            style: "Thin",
            full_name: "Montserrat Thin",
            post_script_name: "Montserrat-Thin",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Thin.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Thin Italic",
            full_name: "Montserrat Thin Italic",
            post_script_name: "Montserrat-ThinItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-ThinItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "ExtraLight",
            full_name: "Montserrat ExtraLight",
            post_script_name: "Montserrat-ExtraLight",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-ExtraLight.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "ExtraLight Italic",
            full_name: "Montserrat ExtraLight Italic",
            post_script_name: "Montserrat-ExtraLightItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-ExtraLightItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Light",
            full_name: "Montserrat Light",
            post_script_name: "Montserrat-Light",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Light.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Light Italic",
            full_name: "Montserrat Light Italic",
            post_script_name: "Montserrat-LightItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-LightItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Regular",
            full_name: "Montserrat Regular",
            post_script_name: "Montserrat-Regular",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Regular.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Italic",
            full_name: "Montserrat Italic",
            post_script_name: "Montserrat-Italic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Italic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Medium",
            full_name: "Montserrat Medium",
            post_script_name: "Montserrat-Medium",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Medium.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Medium Italic",
            full_name: "Montserrat Medium Italic",
            post_script_name: "Montserrat-MediumItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-MediumItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "SemiBold",
            full_name: "Montserrat SemiBold",
            post_script_name: "Montserrat-SemiBold",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-SemiBold.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "SemiBold Italic",
            full_name: "Montserrat SemiBold Italic",
            post_script_name: "Montserrat-SemiBoldItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-SemiBoldItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Bold",
            full_name: "Montserrat Bold",
            post_script_name: "Montserrat-Bold",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Bold.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Bold Italic",
            full_name: "Montserrat Bold Italic",
            post_script_name: "Montserrat-BoldItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-BoldItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "ExtraBold",
            full_name: "Montserrat ExtraBold",
            post_script_name: "Montserrat-ExtraBold",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-ExtraBold.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "ExtraBold Italic",
            full_name: "Montserrat ExtraBold Italic",
            post_script_name: "Montserrat-ExtraBoldItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-ExtraBoldItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Black",
            full_name: "Montserrat Black",
            post_script_name: "Montserrat-Black",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-Black.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat",
            style: "Black Italic",
            full_name: "Montserrat Black Italic",
            post_script_name: "Montserrat-BlackItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "Montserrat-BlackItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
        ]
      )

      provides_font(
        "Montserrat Alternates",
        match_styles_from_file: [
          {
            family_name: "Montserrat Alternates",
            style: "Thin",
            full_name: "Montserrat Alternates Thin",
            post_script_name: "MontserratAlternates-Thin",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Thin.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Thin Italic",
            full_name: "Montserrat Alternates Thin Italic",
            post_script_name: "MontserratAlternates-ThinItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-ThinItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "ExtraLight",
            full_name: "Montserrat Alternates ExtraLight",
            post_script_name: "MontserratAlternates-ExtraLight",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-ExtraLight.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "ExtraLight Italic",
            full_name: "Montserrat Alternates ExtraLight Italic",
            post_script_name: "MontserratAlternates-ExtraLightItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-ExtraLightItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Light",
            full_name: "Montserrat Alternates Light",
            post_script_name: "MontserratAlternates-Light",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Light.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Light Italic",
            full_name: "Montserrat Alternates Light Italic",
            post_script_name: "MontserratAlternates-LightItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-LightItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Regular",
            full_name: "Montserrat Alternates Regular",
            post_script_name: "MontserratAlternates-Regular",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Regular.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Italic",
            full_name: "Montserrat Alternates Italic",
            post_script_name: "MontserratAlternates-Italic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Italic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Medium",
            full_name: "Montserrat Alternates Medium",
            post_script_name: "MontserratAlternates-Medium",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Medium.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Medium Italic",
            full_name: "Montserrat Alternates Medium Italic",
            post_script_name: "MontserratAlternates-MediumItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-MediumItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "SemiBold",
            full_name: "Montserrat Alternates SemiBold",
            post_script_name: "MontserratAlternates-SemiBold",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-SemiBold.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "SemiBold Italic",
            full_name: "Montserrat Alternates SemiBold Italic",
            post_script_name: "MontserratAlternates-SemiBoldItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-SemiBoldItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Bold",
            full_name: "Montserrat Alternates Bold",
            post_script_name: "MontserratAlternates-Bold",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Bold.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Bold Italic",
            full_name: "Montserrat Alternates Bold Italic",
            post_script_name: "MontserratAlternates-BoldItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-BoldItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "ExtraBold",
            full_name: "Montserrat Alternates ExtraBold",
            post_script_name: "MontserratAlternates-ExtraBold",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-ExtraBold.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "ExtraBold Italic",
            full_name: "Montserrat Alternates ExtraBold Italic",
            post_script_name: "MontserratAlternates-ExtraBoldItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-ExtraBoldItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Black",
            full_name: "Montserrat Alternates Black",
            post_script_name: "MontserratAlternates-Black",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-Black.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
          {
            family_name: "Montserrat Alternates",
            style: "Black Italic",
            full_name: "Montserrat Alternates Black Italic",
            post_script_name: "MontserratAlternates-BlackItalic",
            version: "7.200;PS 007.200;hotconv 1.0.88;makeotf.lib2.5.64775",
            filename: "MontserratAlternates-BlackItalic.otf",
            copyright: "Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)",
          },
        ]
      )

      def extract
        resource("montserrat.zip") do |resource|
          zip_extract(resource) do |fontdir|
            match_fonts(fontdir, "Montserrat")
            match_fonts(fontdir, "Montserrat Alternates")
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/Montserrat"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/montserrat"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/Montserrat/MontserratAlternates-Thin.otf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/montserrat/MontserratAlternates-Thin.otf", :exist?
        end
      end

      open_license <<~EOS
  Copyright 2011 The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat)

  This Font Software is licensed under the SIL Open Font License, Version 1.1.
  This license is copied below, and is also available with a FAQ at: http://scripts.sil.org/OFL

  -----------------------------------------------------------
  SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
  -----------------------------------------------------------

  PREAMBLE
  The goals of the Open Font License (OFL) are to stimulate worldwide development of collaborative font projects, to support the font creation efforts of academic and linguistic communities, and to provide a free and open framework in which fonts may be shared and improved in partnership with others.

  The OFL allows the licensed fonts to be used, studied, modified and redistributed freely as long as they are not sold by themselves. The fonts, including any derivative works, can be bundled, embedded, redistributed and/or sold with any software provided that any reserved names are not used by derivative works. The fonts and derivatives, however, cannot be released under any other type of license. The requirement for fonts to remain under this license does not apply to any document created using the fonts or their derivatives.

  DEFINITIONS
  "Font Software" refers to the set of files released by the Copyright Holder(s) under this license and clearly marked as such. This may include source files, build scripts and documentation.

  "Reserved Font Name" refers to any names specified as such after the copyright statement(s).

  "Original Version" refers to the collection of Font Software components as distributed by the Copyright Holder(s).

  "Modified Version" refers to any derivative made by adding to, deleting, or substituting -- in part or in whole -- any of the components of the Original Version, by changing formats or by porting the Font Software to a new environment.

  "Author" refers to any designer, engineer, programmer, technical writer or other person who contributed to the Font Software.

  PERMISSION & CONDITIONS
  Permission is hereby granted, free of charge, to any person obtaining a copy of the Font Software, to use, study, copy, merge, embed, modify, redistribute, and sell modified and unmodified copies of the Font Software, subject to the following conditions:

  1) Neither the Font Software nor any of its individual components, in Original or Modified Versions, may be sold by itself.

  2) Original or Modified Versions of the Font Software may be bundled, redistributed and/or sold with any software, provided that each copy contains the above copyright notice and this license. These can be included either as stand-alone text files, human-readable headers or in the appropriate machine-readable metadata fields within text or binary files as long as those fields can be easily viewed by the user.

  3) No Modified Version of the Font Software may use the Reserved Font Name(s) unless explicit written permission is granted by the corresponding Copyright Holder. This restriction only applies to the primary font name as presented to the users.

  4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font Software shall not be used to promote, endorse or advertise any Modified Version, except to acknowledge the contribution(s) of the Copyright Holder(s) and the Author(s) or with their explicit written permission.

  5) The Font Software, modified or unmodified, in part or in whole, must be distributed entirely under this license, and must not be distributed under any other license. The requirement for fonts to remain under this license does not apply to any document created using the Font Software.

  TERMINATION
  This license becomes null and void if any of the above conditions are not met.

  DISCLAIMER
  THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER DEALINGS IN THE FONT SOFTWARE.

      EOS

    end
  end
end
