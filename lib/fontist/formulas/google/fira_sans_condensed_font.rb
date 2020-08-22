module Fontist
  module Formulas
    class FiraSansCondensedFont < FontFormula
      FULLNAME = "Fira Sans Condensed".freeze
      CLEANNAME = "FiraSansCondensed".freeze

      desc FULLNAME
      homepage "http://www.carrois.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Fira%20Sans%20Condensed"
        sha256 "926226d670df78eed946af68e84f5a006e6aef4218da113ace43f4b2e9be4ec0"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Fira Sans Condensed",
            style: "Thin",
            full_name: "Fira Sans Condensed Thin",
            post_script_name: "FiraSansCondensed-Thin",
            version: "4.203",
            filename: "FiraSansCondensed-Thin.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Thin Italic",
            full_name: "Fira Sans Condensed Thin Italic",
            post_script_name: "FiraSansCondensed-ThinItalic",
            version: "4.203",
            filename: "FiraSansCondensed-ThinItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "ExtraLight",
            full_name: "Fira Sans Condensed ExtraLight",
            post_script_name: "FiraSansCondensed-ExtraLight",
            version: "4.203",
            filename: "FiraSansCondensed-ExtraLight.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "ExtraLight Italic",
            full_name: "Fira Sans Condensed ExtraLight Italic",
            post_script_name: "FiraSansCondensed-ExtraLightItalic",
            version: "4.203",
            filename: "FiraSansCondensed-ExtraLightItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Light",
            full_name: "Fira Sans Condensed Light",
            post_script_name: "FiraSansCondensed-Light",
            version: "4.203",
            filename: "FiraSansCondensed-Light.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Light Italic",
            full_name: "Fira Sans Condensed Light Italic",
            post_script_name: "FiraSansCondensed-LightItalic",
            version: "4.203",
            filename: "FiraSansCondensed-LightItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Regular",
            full_name: "Fira Sans Condensed Regular",
            post_script_name: "FiraSansCondensed-Regular",
            version: "4.203",
            filename: "FiraSansCondensed-Regular.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Italic",
            full_name: "Fira Sans Condensed Italic",
            post_script_name: "FiraSansCondensed-Italic",
            version: "4.203",
            filename: "FiraSansCondensed-Italic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Medium",
            full_name: "Fira Sans Condensed Medium",
            post_script_name: "FiraSansCondensed-Medium",
            version: "4.203",
            filename: "FiraSansCondensed-Medium.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Medium Italic",
            full_name: "Fira Sans Condensed Medium Italic",
            post_script_name: "FiraSansCondensed-MediumItalic",
            version: "4.203",
            filename: "FiraSansCondensed-MediumItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "SemiBold",
            full_name: "Fira Sans Condensed SemiBold",
            post_script_name: "FiraSansCondensed-SemiBold",
            version: "4.203",
            filename: "FiraSansCondensed-SemiBold.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "SemiBold Italic",
            full_name: "Fira Sans Condensed SemiBold Italic",
            post_script_name: "FiraSansCondensed-SemiBoldItalic",
            version: "4.203",
            filename: "FiraSansCondensed-SemiBoldItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Bold",
            full_name: "Fira Sans Condensed Bold",
            post_script_name: "FiraSansCondensed-Bold",
            version: "4.203",
            filename: "FiraSansCondensed-Bold.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Bold Italic",
            full_name: "Fira Sans Condensed Bold Italic",
            post_script_name: "FiraSansCondensed-BoldItalic",
            version: "4.203",
            filename: "FiraSansCondensed-BoldItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "ExtraBold",
            full_name: "Fira Sans Condensed ExtraBold",
            post_script_name: "FiraSansCondensed-ExtraBold",
            version: "4.203",
            filename: "FiraSansCondensed-ExtraBold.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "ExtraBold Italic",
            full_name: "Fira Sans Condensed ExtraBold Italic",
            post_script_name: "FiraSansCondensed-ExtraBoldItalic",
            version: "4.203",
            filename: "FiraSansCondensed-ExtraBoldItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Black",
            full_name: "Fira Sans Condensed Black",
            post_script_name: "FiraSansCondensed-Black",
            version: "4.203",
            filename: "FiraSansCondensed-Black.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
          },
          {
            family_name: "Fira Sans Condensed",
            style: "Black Italic",
            full_name: "Fira Sans Condensed Black Italic",
            post_script_name: "FiraSansCondensed-BlackItalic",
            version: "4.203",
            filename: "FiraSansCondensed-BlackItalic.ttf",
            copyright: "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A.",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/FiraSansCondensed-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/FiraSansCondensed-Thin.ttf", :exist?
        end
      end

      copyright "Digitized data copyright 2012-2016, The Mozilla Foundation and Telefonica S.A."
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright (c) 2012-2015, The Mozilla Foundation and Telefonica S.A.

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
