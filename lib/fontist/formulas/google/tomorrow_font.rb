module Fontist
  module Formulas
    class TomorrowFont < FontFormula
      FULLNAME = "Tomorrow".freeze
      CLEANNAME = "Tomorrow".freeze

      desc FULLNAME
      homepage "http://www.justintype.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Tomorrow"
        sha256 "acd52b96f45a956774c29a1bf6035c47b3f94f5f5c467518e442cbc57dc81338"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Tomorrow",
            style: "Thin",
            full_name: "Tomorrow Thin",
            post_script_name: "Tomorrow-Thin",
            version: "2.002",
            filename: "Tomorrow-Thin.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Thin Italic",
            full_name: "Tomorrow Thin Italic",
            post_script_name: "Tomorrow-ThinItalic",
            version: "2.002",
            filename: "Tomorrow-ThinItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "ExtraLight",
            full_name: "Tomorrow ExtraLight",
            post_script_name: "Tomorrow-ExtraLight",
            version: "2.002",
            filename: "Tomorrow-ExtraLight.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "ExtraLight Italic",
            full_name: "Tomorrow ExtraLight Italic",
            post_script_name: "Tomorrow-ExtraLightItalic",
            version: "2.002",
            filename: "Tomorrow-ExtraLightItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Light",
            full_name: "Tomorrow Light",
            post_script_name: "Tomorrow-Light",
            version: "2.002",
            filename: "Tomorrow-Light.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Light Italic",
            full_name: "Tomorrow Light Italic",
            post_script_name: "Tomorrow-LightItalic",
            version: "2.002",
            filename: "Tomorrow-LightItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Regular",
            full_name: "Tomorrow Regular",
            post_script_name: "Tomorrow-Regular",
            version: "2.002",
            filename: "Tomorrow-Regular.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Italic",
            full_name: "Tomorrow Italic",
            post_script_name: "Tomorrow-Italic",
            version: "2.002",
            filename: "Tomorrow-Italic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Medium",
            full_name: "Tomorrow Medium",
            post_script_name: "Tomorrow-Medium",
            version: "2.002",
            filename: "Tomorrow-Medium.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Medium Italic",
            full_name: "Tomorrow Medium Italic",
            post_script_name: "Tomorrow-MediumItalic",
            version: "2.002",
            filename: "Tomorrow-MediumItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "SemiBold",
            full_name: "Tomorrow SemiBold",
            post_script_name: "Tomorrow-SemiBold",
            version: "2.002",
            filename: "Tomorrow-SemiBold.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "SemiBold Italic",
            full_name: "Tomorrow SemiBold Italic",
            post_script_name: "Tomorrow-SemiBoldItalic",
            version: "2.002",
            filename: "Tomorrow-SemiBoldItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Bold",
            full_name: "Tomorrow Bold",
            post_script_name: "Tomorrow-Bold",
            version: "2.002",
            filename: "Tomorrow-Bold.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Bold Italic",
            full_name: "Tomorrow Bold Italic",
            post_script_name: "Tomorrow-BoldItalic",
            version: "2.002",
            filename: "Tomorrow-BoldItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "ExtraBold",
            full_name: "Tomorrow ExtraBold",
            post_script_name: "Tomorrow-ExtraBold",
            version: "2.002",
            filename: "Tomorrow-ExtraBold.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "ExtraBold Italic",
            full_name: "Tomorrow ExtraBold Italic",
            post_script_name: "Tomorrow-ExtraBoldItalic",
            version: "2.002",
            filename: "Tomorrow-ExtraBoldItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Black",
            full_name: "Tomorrow Black",
            post_script_name: "Tomorrow-Black",
            version: "2.002",
            filename: "Tomorrow-Black.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
          },
          {
            family_name: "Tomorrow",
            style: "Black Italic",
            full_name: "Tomorrow Black Italic",
            post_script_name: "Tomorrow-BlackItalic",
            version: "2.002",
            filename: "Tomorrow-BlackItalic.ttf",
            copyright: "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Tomorrow-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Tomorrow-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2019 The Tomorrow Project Authors (https://github.com/MonicaRizzolli/Tomorrow)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright 2019 The Tomorrow Project Authors (github.com/MonicaRizzolli/Tomorrow)

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
