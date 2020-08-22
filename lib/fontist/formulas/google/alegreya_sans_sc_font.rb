module Fontist
  module Formulas
    class AlegreyaSansSCFont < FontFormula
      FULLNAME = "Alegreya Sans SC".freeze
      CLEANNAME = "AlegreyaSansSC".freeze

      desc FULLNAME
      homepage "http://www.huertatipografica.com.ar"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Alegreya%20Sans%20SC"
        sha256 "451d8226200e1d6641abe7e5ec25ae7a4818f7e2cc53dfeca9d17a0825fb5b3b"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Alegreya Sans SC",
            style: "Thin",
            full_name: "Alegreya Sans SC Thin",
            post_script_name: "AlegreyaSansSC-Thin",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Thin.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Thin Italic",
            full_name: "Alegreya Sans SC Thin Italic",
            post_script_name: "AlegreyaSansSC-ThinItalic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-ThinItalic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Light",
            full_name: "Alegreya Sans SC Light",
            post_script_name: "AlegreyaSansSC-Light",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Light.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Light Italic",
            full_name: "Alegreya Sans SC Light Italic",
            post_script_name: "AlegreyaSansSC-LightItalic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-LightItalic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Regular",
            full_name: "Alegreya Sans SC Regular",
            post_script_name: "AlegreyaSansSC-Regular",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Regular.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Italic",
            full_name: "Alegreya Sans SC Italic",
            post_script_name: "AlegreyaSansSC-Italic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Italic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Medium",
            full_name: "Alegreya Sans SC Medium",
            post_script_name: "AlegreyaSansSC-Medium",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Medium.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Medium Italic",
            full_name: "Alegreya Sans SC Medium Italic",
            post_script_name: "AlegreyaSansSC-MediumItalic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-MediumItalic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Bold",
            full_name: "Alegreya Sans SC Bold",
            post_script_name: "AlegreyaSansSC-Bold",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Bold.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Bold Italic",
            full_name: "Alegreya Sans SC Bold Italic",
            post_script_name: "AlegreyaSansSC-BoldItalic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-BoldItalic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "ExtraBold",
            full_name: "Alegreya Sans SC ExtraBold",
            post_script_name: "AlegreyaSansSC-ExtraBold",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-ExtraBold.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "ExtraBold Italic",
            full_name: "Alegreya Sans SC ExtraBold Italic",
            post_script_name: "AlegreyaSansSC-ExtraBoldItalic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-ExtraBoldItalic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Black",
            full_name: "Alegreya Sans SC Black",
            post_script_name: "AlegreyaSansSC-Black",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-Black.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
          },
          {
            family_name: "Alegreya Sans SC",
            style: "Black Italic",
            full_name: "Alegreya Sans SC Black Italic",
            post_script_name: "AlegreyaSansSC-BlackItalic",
            version: "2.003; ttfautohint (v1.6)",
            filename: "AlegreyaSansSC-BlackItalic.ttf",
            copyright: "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/AlegreyaSansSC-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/AlegreyaSansSC-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
        Copyright 2013 The Alegreya Sans Project Authors (https://github.com/huertatipografica/Alegreya-Sans)

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
