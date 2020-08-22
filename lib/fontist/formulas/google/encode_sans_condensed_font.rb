module Fontist
  module Formulas
    class EncodeSansCondensedFont < FontFormula
      FULLNAME = "Encode Sans Condensed".freeze
      CLEANNAME = "EncodeSansCondensed".freeze

      desc FULLNAME
      homepage "http://www.impallari.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Encode%20Sans%20Condensed"
        sha256 "b9e7f731ca64bbd4bd988a20936a4790f30c694c7d06e2a26b7403c1e6db8e87"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Encode Sans Condensed",
            style: "Thin",
            full_name: "Encode Sans Condensed Thin",
            post_script_name: "EncodeSansCondensed-Thin",
            version: "2.000",
            filename: "EncodeSansCondensed-Thin.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "ExtraLight",
            full_name: "Encode Sans Condensed ExtraLight",
            post_script_name: "EncodeSansCondensed-ExtraLight",
            version: "2.000",
            filename: "EncodeSansCondensed-ExtraLight.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "Light",
            full_name: "Encode Sans Condensed Light",
            post_script_name: "EncodeSansCondensed-Light",
            version: "2.000",
            filename: "EncodeSansCondensed-Light.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "Regular",
            full_name: "Encode Sans Condensed Regular",
            post_script_name: "EncodeSansCondensed-Regular",
            version: "2.000",
            filename: "EncodeSansCondensed-Regular.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "Medium",
            full_name: "Encode Sans Condensed Medium",
            post_script_name: "EncodeSansCondensed-Medium",
            version: "2.000",
            filename: "EncodeSansCondensed-Medium.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "SemiBold",
            full_name: "Encode Sans Condensed SemiBold",
            post_script_name: "EncodeSansCondensed-SemiBold",
            version: "2.000",
            filename: "EncodeSansCondensed-SemiBold.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "Bold",
            full_name: "Encode Sans Condensed Bold",
            post_script_name: "EncodeSansCondensed-Bold",
            version: "2.000",
            filename: "EncodeSansCondensed-Bold.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "ExtraBold",
            full_name: "Encode Sans Condensed ExtraBold",
            post_script_name: "EncodeSansCondensed-ExtraBold",
            version: "2.000",
            filename: "EncodeSansCondensed-ExtraBold.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
          },
          {
            family_name: "Encode Sans Condensed",
            style: "Black",
            full_name: "Encode Sans Condensed Black",
            post_script_name: "EncodeSansCondensed-Black",
            version: "2.000",
            filename: "EncodeSansCondensed-Black.ttf",
            copyright: "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\".",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/EncodeSansCondensed-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/EncodeSansCondensed-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name \"Encode Sans\"."
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright 2012 The Encode Project Authors (impallari@gmail.com), with Reserved Font Name "Encode Sans”.

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
