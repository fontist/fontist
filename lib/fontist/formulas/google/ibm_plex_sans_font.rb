module Fontist
  module Formulas
    class IBMPlexSansFont < FontFormula
      FULLNAME = "IBM Plex Sans".freeze
      CLEANNAME = "IBMPlexSans".freeze

      desc FULLNAME
      homepage "http://www.boldmonday.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=IBM%20Plex%20Sans"
        sha256 "7bd5219079b079a35f83c06734280d41e1c32859dbba3ec27a660938c73acf03"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "IBM Plex Sans",
            style: "Thin",
            full_name: "IBM Plex Sans Thin",
            post_script_name: "IBMPlexSans-Thin",
            version: "3.1",
            filename: "IBMPlexSans-Thin.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Thin Italic",
            full_name: "IBM Plex Sans Thin Italic",
            post_script_name: "IBMPlexSans-ThinItalic",
            version: "3.1",
            filename: "IBMPlexSans-ThinItalic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "ExtraLight",
            full_name: "IBM Plex Sans ExtraLight",
            post_script_name: "IBMPlexSans-ExtraLight",
            version: "3.1",
            filename: "IBMPlexSans-ExtraLight.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "ExtraLight Italic",
            full_name: "IBM Plex Sans ExtraLight Italic",
            post_script_name: "IBMPlexSans-ExtraLightItalic",
            version: "3.1",
            filename: "IBMPlexSans-ExtraLightItalic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Light",
            full_name: "IBM Plex Sans Light",
            post_script_name: "IBMPlexSans-Light",
            version: "3.1",
            filename: "IBMPlexSans-Light.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Light Italic",
            full_name: "IBM Plex Sans Light Italic",
            post_script_name: "IBMPlexSans-LightItalic",
            version: "3.1",
            filename: "IBMPlexSans-LightItalic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Regular",
            full_name: "IBM Plex Sans",
            post_script_name: "IBMPlexSans",
            version: "3.1",
            filename: "IBMPlexSans-Regular.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Italic",
            full_name: "IBM Plex Sans Italic",
            post_script_name: "IBMPlexSans-Italic",
            version: "3.1",
            filename: "IBMPlexSans-Italic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Medium",
            full_name: "IBM Plex Sans Medium",
            post_script_name: "IBMPlexSans-Medium",
            version: "3.1",
            filename: "IBMPlexSans-Medium.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Medium Italic",
            full_name: "IBM Plex Sans Medium Italic",
            post_script_name: "IBMPlexSans-MediumItalic",
            version: "3.1",
            filename: "IBMPlexSans-MediumItalic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "SemiBold",
            full_name: "IBM Plex Sans SemiBold",
            post_script_name: "IBMPlexSans-SemiBold",
            version: "3.1",
            filename: "IBMPlexSans-SemiBold.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "SemiBold Italic",
            full_name: "IBM Plex Sans SemiBold Italic",
            post_script_name: "IBMPlexSans-SemiBoldItalic",
            version: "3.1",
            filename: "IBMPlexSans-SemiBoldItalic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Bold",
            full_name: "IBM Plex Sans Bold",
            post_script_name: "IBMPlexSans-Bold",
            version: "3.1",
            filename: "IBMPlexSans-Bold.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
          },
          {
            family_name: "IBM Plex Sans",
            style: "Bold Italic",
            full_name: "IBM Plex Sans Bold Italic",
            post_script_name: "IBMPlexSans-BoldItalic",
            version: "3.1",
            filename: "IBMPlexSans-BoldItalic.ttf",
            copyright: "Copyright 2018 IBM Corp. All rights reserved.",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/IBMPlexSans-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/IBMPlexSans-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2018 IBM Corp. All rights reserved."
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright © 2017 IBM Corp. with Reserved Font Name "Plex"

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
