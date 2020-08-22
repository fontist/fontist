module Fontist
  module Formulas
    class BarlowSemiCondensedFont < FontFormula
      FULLNAME = "Barlow Semi Condensed".freeze
      CLEANNAME = "BarlowSemiCondensed".freeze

      desc FULLNAME
      homepage "https://tribby.com/"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Barlow%20Semi%20Condensed"
        sha256 "5ab33055584c760da2c9f7b48a2088f6d253cc645c5ab43843bc138255c7c132"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Barlow Semi Condensed",
            style: "Thin",
            full_name: "Barlow Semi Condensed Thin",
            post_script_name: "BarlowSemiCondensed-Thin",
            version: "1.408",
            filename: "BarlowSemiCondensed-Thin.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Thin Italic",
            full_name: "Barlow Semi Condensed Thin Italic",
            post_script_name: "BarlowSemiCondensed-ThinItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-ThinItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "ExtraLight",
            full_name: "Barlow Semi Condensed ExtraLight",
            post_script_name: "BarlowSemiCondensed-ExtraLight",
            version: "1.408",
            filename: "BarlowSemiCondensed-ExtraLight.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "ExtraLight Italic",
            full_name: "Barlow Semi Condensed ExtraLight Italic",
            post_script_name: "BarlowSemiCondensed-ExtraLightItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-ExtraLightItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Light",
            full_name: "Barlow Semi Condensed Light",
            post_script_name: "BarlowSemiCondensed-Light",
            version: "1.408",
            filename: "BarlowSemiCondensed-Light.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Light Italic",
            full_name: "Barlow Semi Condensed Light Italic",
            post_script_name: "BarlowSemiCondensed-LightItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-LightItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Regular",
            full_name: "Barlow Semi Condensed Regular",
            post_script_name: "BarlowSemiCondensed-Regular",
            version: "1.408",
            filename: "BarlowSemiCondensed-Regular.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Italic",
            full_name: "Barlow Semi Condensed Italic",
            post_script_name: "BarlowSemiCondensed-Italic",
            version: "1.408",
            filename: "BarlowSemiCondensed-Italic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Medium",
            full_name: "Barlow Semi Condensed Medium",
            post_script_name: "BarlowSemiCondensed-Medium",
            version: "1.408",
            filename: "BarlowSemiCondensed-Medium.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Medium Italic",
            full_name: "Barlow Semi Condensed Medium Italic",
            post_script_name: "BarlowSemiCondensed-MediumItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-MediumItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "SemiBold",
            full_name: "Barlow Semi Condensed SemiBold",
            post_script_name: "BarlowSemiCondensed-SemiBold",
            version: "1.408",
            filename: "BarlowSemiCondensed-SemiBold.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "SemiBold Italic",
            full_name: "Barlow Semi Condensed SemiBold Italic",
            post_script_name: "BarlowSemiCondensed-SemiBoldItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-SemiBoldItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Bold",
            full_name: "Barlow Semi Condensed Bold",
            post_script_name: "BarlowSemiCondensed-Bold",
            version: "1.408",
            filename: "BarlowSemiCondensed-Bold.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Bold Italic",
            full_name: "Barlow Semi Condensed Bold Italic",
            post_script_name: "BarlowSemiCondensed-BoldItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-BoldItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "ExtraBold",
            full_name: "Barlow Semi Condensed ExtraBold",
            post_script_name: "BarlowSemiCondensed-ExtraBold",
            version: "1.408",
            filename: "BarlowSemiCondensed-ExtraBold.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "ExtraBold Italic",
            full_name: "Barlow Semi Condensed ExtraBold Italic",
            post_script_name: "BarlowSemiCondensed-ExtraBoldItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-ExtraBoldItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Black",
            full_name: "Barlow Semi Condensed Black",
            post_script_name: "BarlowSemiCondensed-Black",
            version: "1.408",
            filename: "BarlowSemiCondensed-Black.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow Semi Condensed",
            style: "Black Italic",
            full_name: "Barlow Semi Condensed Black Italic",
            post_script_name: "BarlowSemiCondensed-BlackItalic",
            version: "1.408",
            filename: "BarlowSemiCondensed-BlackItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/BarlowSemiCondensed-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/BarlowSemiCondensed-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)

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
