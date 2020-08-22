module Fontist
  module Formulas
    class TavirajFont < FontFormula
      FULLNAME = "Taviraj".freeze
      CLEANNAME = "Taviraj".freeze

      desc FULLNAME
      homepage "www.cadsondemak.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Taviraj"
        sha256 "25038d4dfa48636582f1ee9b4fe2711baccfda2eea26f0671abe8070a4b2bedb"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Taviraj",
            style: "Thin",
            full_name: "Taviraj Thin",
            post_script_name: "Taviraj-Thin",
            version: "1.001",
            filename: "Taviraj-Thin.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Thin Italic",
            full_name: "Taviraj Thin Italic",
            post_script_name: "Taviraj-ThinItalic",
            version: "1.001",
            filename: "Taviraj-ThinItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "ExtraLight",
            full_name: "Taviraj ExtraLight",
            post_script_name: "Taviraj-ExtraLight",
            version: "1.001",
            filename: "Taviraj-ExtraLight.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "ExtraLight Italic",
            full_name: "Taviraj ExtraLight Italic",
            post_script_name: "Taviraj-ExtraLightItalic",
            version: "1.001",
            filename: "Taviraj-ExtraLightItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Light",
            full_name: "Taviraj Light",
            post_script_name: "Taviraj-Light",
            version: "1.001",
            filename: "Taviraj-Light.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Light Italic",
            full_name: "Taviraj Light Italic",
            post_script_name: "Taviraj-LightItalic",
            version: "1.001",
            filename: "Taviraj-LightItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Regular",
            full_name: "Taviraj Regular",
            post_script_name: "Taviraj-Regular",
            version: "1.001",
            filename: "Taviraj-Regular.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Italic",
            full_name: "Taviraj Italic",
            post_script_name: "Taviraj-Italic",
            version: "1.001",
            filename: "Taviraj-Italic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Medium",
            full_name: "Taviraj Medium",
            post_script_name: "Taviraj-Medium",
            version: "1.001",
            filename: "Taviraj-Medium.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Medium Italic",
            full_name: "Taviraj Medium Italic",
            post_script_name: "Taviraj-MediumItalic",
            version: "1.001",
            filename: "Taviraj-MediumItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "SemiBold",
            full_name: "Taviraj SemiBold",
            post_script_name: "Taviraj-SemiBold",
            version: "1.001",
            filename: "Taviraj-SemiBold.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "SemiBold Italic",
            full_name: "Taviraj SemiBold Italic",
            post_script_name: "Taviraj-SemiBoldItalic",
            version: "1.001",
            filename: "Taviraj-SemiBoldItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Bold",
            full_name: "Taviraj Bold",
            post_script_name: "Taviraj-Bold",
            version: "1.001",
            filename: "Taviraj-Bold.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Bold Italic",
            full_name: "Taviraj Bold Italic",
            post_script_name: "Taviraj-BoldItalic",
            version: "1.001",
            filename: "Taviraj-BoldItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "ExtraBold",
            full_name: "Taviraj ExtraBold",
            post_script_name: "Taviraj-ExtraBold",
            version: "1.001",
            filename: "Taviraj-ExtraBold.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "ExtraBold Italic",
            full_name: "Taviraj ExtraBold Italic",
            post_script_name: "Taviraj-ExtraBoldItalic",
            version: "1.001",
            filename: "Taviraj-ExtraBoldItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Black",
            full_name: "Taviraj Black",
            post_script_name: "Taviraj-Black",
            version: "1.001",
            filename: "Taviraj-Black.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Taviraj",
            style: "Black Italic",
            full_name: "Taviraj Black Italic",
            post_script_name: "Taviraj-BlackItalic",
            version: "1.001",
            filename: "Taviraj-BlackItalic.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Taviraj-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Taviraj-Thin.ttf", :exist?
        end
      end

      copyright "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)

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
