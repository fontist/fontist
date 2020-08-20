module Fontist
  module Formulas
    class LibreFranklinFont < FontFormula
      FULLNAME = "Libre Franklin".freeze
      CLEANNAME = "LibreFranklin".freeze

      desc FULLNAME
      homepage "http://www.impallari.com/"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Libre%20Franklin"
        sha256 "f380b1849e81bf21a69f40fcdedb68e679eac946a0e45f79fdba6d0619627df4"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Libre Franklin",
            style: "Thin",
            full_name: "LibreFranklin-Thin",
            post_script_name: "LibreFranklin-Thin",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Thin.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Thin Italic",
            full_name: "Libre Franklin Thin Italic",
            post_script_name: "LibreFranklin-ThinItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-ThinItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "ExtraLight",
            full_name: "LibreFranklin-ExtraLight",
            post_script_name: "LibreFranklin-ExtraLight",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-ExtraLight.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "ExtraLight Italic",
            full_name: "Libre Franklin ExtraLight Italic",
            post_script_name: "LibreFranklin-ExtraLightItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-ExtraLightItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Light",
            full_name: "LibreFranklin-Light",
            post_script_name: "LibreFranklin-Light",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Light.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Light Italic",
            full_name: "Libre Franklin Light Italic",
            post_script_name: "LibreFranklin-LightItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-LightItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Regular",
            full_name: "LibreFranklin-Regular",
            post_script_name: "LibreFranklin-Regular",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Regular.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Italic",
            full_name: "Libre Franklin Italic",
            post_script_name: "LibreFranklin-Italic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Italic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Medium",
            full_name: "LibreFranklin-Medium",
            post_script_name: "LibreFranklin-Medium",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Medium.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Medium Italic",
            full_name: "Libre Franklin Medium Italic",
            post_script_name: "LibreFranklin-MediumItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-MediumItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "SemiBold",
            full_name: "LibreFranklin-SemiBold",
            post_script_name: "LibreFranklin-SemiBold",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-SemiBold.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "SemiBold Italic",
            full_name: "Libre Franklin SemiBold Italic",
            post_script_name: "LibreFranklin-SemiBoldItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-SemiBoldItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Bold",
            full_name: "Libre Franklin Bold",
            post_script_name: "LibreFranklin-Bold",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Bold.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Bold Italic",
            full_name: "Libre Franklin Bold Italic",
            post_script_name: "LibreFranklin-BoldItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-BoldItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "ExtraBold",
            full_name: "LibreFranklin-ExtraBold",
            post_script_name: "LibreFranklin-ExtraBold",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-ExtraBold.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "ExtraBold Italic",
            full_name: "Libre Franklin ExtraBold Italic",
            post_script_name: "LibreFranklin-ExtraBoldItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-ExtraBoldItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Black",
            full_name: "LibreFranklin-Black",
            post_script_name: "LibreFranklin-Black",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-Black.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
          },
          {
            family_name: "Libre Franklin",
            style: "Black Italic",
            full_name: "Libre Franklin Black Italic",
            post_script_name: "LibreFranklin-BlackItalic",
            version: "1.002; ttfautohint (v1.5)",
            description: "Libre Franklin is a reinterpretation and expansion of the 1912 Morris Fuller Benton’s classic.",
            filename: "LibreFranklin-BlackItalic.ttf",
            copyright: "Copyright (c) 2015, Impallari Type (www.impallari.com)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/LibreFranklin-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/LibreFranklin-Thin.ttf", :exist?
        end
      end

      copyright "Copyright (c) 2015, Impallari Type (www.impallari.com)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright (c) 2015, Impallari Type (www.impallari.com)
        This Font Software is licensed under the SIL Open Font License, Version 1.1.
        This license is copied below, and is also available with a FAQ at:
        http://scripts.sil.org/OFL


        -----------------------------------------------------------
        SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
        -----------------------------------------------------------

        PREAMBLE
        The goals of the Open Font License (OFL) are to stimulate worldwide
        development of collaborative font projects, to support the font creation
        efforts of academic and linguistic communities, and to provide a free and
        open framework in which fonts may be shared and improved in partnership
        with others.

        The OFL allows the licensed fonts to be used, studied, modified and
        redistributed freely as long as they are not sold by themselves. The
        fonts, including any derivative works, can be bundled, embedded,
        redistributed and/or sold with any software provided that any reserved
        names are not used by derivative works. The fonts and derivatives,
        however, cannot be released under any other type of license. The
        requirement for fonts to remain under this license does not apply
        to any document created using the fonts or their derivatives.

        DEFINITIONS
        "Font Software" refers to the set of files released by the Copyright
        Holder(s) under this license and clearly marked as such. This may
        include source files, build scripts and documentation.

        "Reserved Font Name" refers to any names specified as such after the
        copyright statement(s).

        "Original Version" refers to the collection of Font Software components as
        distributed by the Copyright Holder(s).

        "Modified Version" refers to any derivative made by adding to, deleting,
        or substituting -- in part or in whole -- any of the components of the
        Original Version, by changing formats or by porting the Font Software to a
        new environment.

        "Author" refers to any designer, engineer, programmer, technical
        writer or other person who contributed to the Font Software.

        PERMISSION & CONDITIONS
        Permission is hereby granted, free of charge, to any person obtaining
        a copy of the Font Software, to use, study, copy, merge, embed, modify,
        redistribute, and sell modified and unmodified copies of the Font
        Software, subject to the following conditions:

        1) Neither the Font Software nor any of its individual components,
        in Original or Modified Versions, may be sold by itself.

        2) Original or Modified Versions of the Font Software may be bundled,
        redistributed and/or sold with any software, provided that each copy
        contains the above copyright notice and this license. These can be
        included either as stand-alone text files, human-readable headers or
        in the appropriate machine-readable metadata fields within text or
        binary files as long as those fields can be easily viewed by the user.

        3) No Modified Version of the Font Software may use the Reserved Font
        Name(s) unless explicit written permission is granted by the corresponding
        Copyright Holder. This restriction only applies to the primary font name as
        presented to the users.

        4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
        Software shall not be used to promote, endorse or advertise any
        Modified Version, except to acknowledge the contribution(s) of the
        Copyright Holder(s) and the Author(s) or with their explicit written
        permission.

        5) The Font Software, modified or unmodified, in part or in whole,
        must be distributed entirely under this license, and must not be
        distributed under any other license. The requirement for fonts to
        remain under this license does not apply to any document created
        using the Font Software.

        TERMINATION
        This license becomes null and void if any of the above conditions are
        not met.

        DISCLAIMER
        THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
        EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
        OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
        COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
        INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
        DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
        FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
        OTHER DEALINGS IN THE FONT SOFTWARE.
      TEXT
    end
  end
end
