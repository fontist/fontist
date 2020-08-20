module Fontist
  module Formulas
    class KrubFont < FontFormula
      FULLNAME = "Krub".freeze
      CLEANNAME = "Krub".freeze

      desc FULLNAME
      homepage "http://www.cadsondemak.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Krub"
        sha256 "6f9c0c5a0f237b0c501fed5e290bcc17b5461476b98d31aed45e3da3240d3c48"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Krub",
            style: "ExtraLight",
            full_name: "Krub ExtraLight",
            post_script_name: "Krub-ExtraLight",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-ExtraLight.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "ExtraLight Italic",
            full_name: "Krub ExtraLight Italic",
            post_script_name: "Krub-ExtraLightItalic",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-ExtraLightItalic.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Light",
            full_name: "Krub Light",
            post_script_name: "Krub-Light",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-Light.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Light Italic",
            full_name: "Krub Light Italic",
            post_script_name: "Krub-LightItalic",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-LightItalic.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Regular",
            full_name: "Krub Regular",
            post_script_name: "Krub-Regular",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-Regular.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Italic",
            full_name: "Krub Italic",
            post_script_name: "Krub-Italic",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-Italic.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Medium",
            full_name: "Krub Medium",
            post_script_name: "Krub-Medium",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-Medium.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Medium Italic",
            full_name: "Krub Medium Italic",
            post_script_name: "Krub-MediumItalic",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-MediumItalic.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "SemiBold",
            full_name: "Krub SemiBold",
            post_script_name: "Krub-SemiBold",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-SemiBold.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "SemiBold Italic",
            full_name: "Krub SemiBold Italic",
            post_script_name: "Krub-SemiBoldItalic",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-SemiBoldItalic.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Bold",
            full_name: "Krub Bold",
            post_script_name: "Krub-Bold",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-Bold.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
          },
          {
            family_name: "Krub",
            style: "Bold Italic",
            full_name: "Krub Bold Italic",
            post_script_name: "Krub-BoldItalic",
            version: "1.000; ttfautohint (v1.6)",
            filename: "Krub-BoldItalic.ttf",
            copyright: "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Krub-ExtraLight.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Krub-ExtraLight.ttf", :exist?
        end
      end

      copyright "Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright 2018 The Krub Project Authors (https://github.com/cadsondemak/Krub)

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
