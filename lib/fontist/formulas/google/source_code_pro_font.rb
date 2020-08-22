module Fontist
  module Formulas
    class SourceCodeProFont < FontFormula
      FULLNAME = "Source Code Pro".freeze
      CLEANNAME = "SourceCodePro".freeze

      desc FULLNAME
      homepage "http://www.adobe.com/type"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Source%20Code%20Pro"
        sha256 "c63a50846ceb3998d7b24d6d1ce872852e05a71a76ffe38ef25b1170b2362a69"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Source Code Pro",
            style: "ExtraLight",
            full_name: "Source Code Pro ExtraLight",
            post_script_name: "SourceCodePro-ExtraLight",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-ExtraLight.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "ExtraLight Italic",
            full_name: "Source Code Pro ExtraLight Italic",
            post_script_name: "SourceCodePro-ExtraLightIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-ExtraLightItalic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Light",
            full_name: "Source Code Pro Light",
            post_script_name: "SourceCodePro-Light",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Light.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Light Italic",
            full_name: "Source Code Pro Light Italic",
            post_script_name: "SourceCodePro-LightIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-LightItalic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Regular",
            full_name: "Source Code Pro",
            post_script_name: "SourceCodePro-Regular",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Regular.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Italic",
            full_name: "Source Code Pro Italic",
            post_script_name: "SourceCodePro-It",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Italic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Medium",
            full_name: "Source Code Pro Medium",
            post_script_name: "SourceCodePro-Medium",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Medium.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Medium Italic",
            full_name: "Source Code Pro Medium Italic",
            post_script_name: "SourceCodePro-MediumIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-MediumItalic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Semibold",
            full_name: "Source Code Pro Semibold",
            post_script_name: "SourceCodePro-Semibold",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-SemiBold.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Semibold Italic",
            full_name: "Source Code Pro Semibold Italic",
            post_script_name: "SourceCodePro-SemiboldIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-SemiBoldItalic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Bold",
            full_name: "Source Code Pro Bold",
            post_script_name: "SourceCodePro-Bold",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Bold.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Bold Italic",
            full_name: "Source Code Pro Bold Italic",
            post_script_name: "SourceCodePro-BoldIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-BoldItalic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Black",
            full_name: "Source Code Pro Black",
            post_script_name: "SourceCodePro-Black",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Black.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Black Italic",
            full_name: "Source Code Pro Black Italic",
            post_script_name: "SourceCodePro-BlackIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-BlackItalic.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/SourceCodePro-ExtraLight.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/SourceCodePro-ExtraLight.ttf", :exist?
        end
      end

      copyright "Copyright 2010, 2012 Adobe Systems Incorporated. All Rights Reserved."
      license_url "http://www.adobe.com/type/legal.html"

      open_license <<~TEXT
        Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name 'Source'. All Rights Reserved. Source is a trademark of Adobe Systems Incorporated in the United States and/or other countries.

        This Font Software is licensed under the SIL Open Font License, Version 1.1.

        This license is copied below, and is also available with a FAQ at: http://scripts.sil.org/OFL


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
