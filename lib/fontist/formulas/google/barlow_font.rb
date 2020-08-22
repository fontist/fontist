module Fontist
  module Formulas
    class BarlowFont < FontFormula
      FULLNAME = "Barlow".freeze
      CLEANNAME = "Barlow".freeze

      desc FULLNAME
      homepage "https://tribby.com/"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Barlow"
        sha256 "8c6707dfc9ffc86b05e46b4969563f12885a78441c0fc3ce1d00b3ac4ea984fb"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Barlow",
            style: "Thin",
            full_name: "Barlow Thin",
            post_script_name: "Barlow-Thin",
            version: "1.408",
            filename: "Barlow-Thin.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Thin Italic",
            full_name: "Barlow Thin Italic",
            post_script_name: "Barlow-ThinItalic",
            version: "1.408",
            filename: "Barlow-ThinItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "ExtraLight",
            full_name: "Barlow ExtraLight",
            post_script_name: "Barlow-ExtraLight",
            version: "1.408",
            filename: "Barlow-ExtraLight.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "ExtraLight Italic",
            full_name: "Barlow ExtraLight Italic",
            post_script_name: "Barlow-ExtraLightItalic",
            version: "1.408",
            filename: "Barlow-ExtraLightItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Light",
            full_name: "Barlow Light",
            post_script_name: "Barlow-Light",
            version: "1.408",
            filename: "Barlow-Light.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Light Italic",
            full_name: "Barlow Light Italic",
            post_script_name: "Barlow-LightItalic",
            version: "1.408",
            filename: "Barlow-LightItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Regular",
            full_name: "Barlow Regular",
            post_script_name: "Barlow-Regular",
            version: "1.408",
            filename: "Barlow-Regular.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Italic",
            full_name: "Barlow Italic",
            post_script_name: "Barlow-Italic",
            version: "1.408",
            filename: "Barlow-Italic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Medium",
            full_name: "Barlow Medium",
            post_script_name: "Barlow-Medium",
            version: "1.408",
            filename: "Barlow-Medium.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Medium Italic",
            full_name: "Barlow Medium Italic",
            post_script_name: "Barlow-MediumItalic",
            version: "1.408",
            filename: "Barlow-MediumItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "SemiBold",
            full_name: "Barlow SemiBold",
            post_script_name: "Barlow-SemiBold",
            version: "1.408",
            filename: "Barlow-SemiBold.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "SemiBold Italic",
            full_name: "Barlow SemiBold Italic",
            post_script_name: "Barlow-SemiBoldItalic",
            version: "1.408",
            filename: "Barlow-SemiBoldItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Bold",
            full_name: "Barlow Bold",
            post_script_name: "Barlow-Bold",
            version: "1.408",
            filename: "Barlow-Bold.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Bold Italic",
            full_name: "Barlow Bold Italic",
            post_script_name: "Barlow-BoldItalic",
            version: "1.408",
            filename: "Barlow-BoldItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "ExtraBold",
            full_name: "Barlow ExtraBold",
            post_script_name: "Barlow-ExtraBold",
            version: "1.408",
            filename: "Barlow-ExtraBold.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "ExtraBold Italic",
            full_name: "Barlow ExtraBold Italic",
            post_script_name: "Barlow-ExtraBoldItalic",
            version: "1.408",
            filename: "Barlow-ExtraBoldItalic.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Black",
            full_name: "Barlow Black",
            post_script_name: "Barlow-Black",
            version: "1.408",
            filename: "Barlow-Black.ttf",
            copyright: "Copyright 2017 The Barlow Project Authors (https://github.com/jpt/barlow)",
          },
          {
            family_name: "Barlow",
            style: "Black Italic",
            full_name: "Barlow Black Italic",
            post_script_name: "Barlow-BlackItalic",
            version: "1.408",
            filename: "Barlow-BlackItalic.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Barlow-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Barlow-Thin.ttf", :exist?
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
