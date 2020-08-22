module Fontist
  module Formulas
    class StixFont < FontFormula
      desc "stixfonts"
      homepage "https://www.stixfonts.org"

      resource "stix.zip" do
        url "https://github.com/stipub/stixfonts/raw/master/zipfiles/STIXv2.0.2.zip"
        sha256 "fef26941bf7eeab7ed6400a386211ba11360f0b2df22002382ceb3e2b551179d"
      end

      provides_font(
        "STIX Two Math",
        match_styles_from_file: [
          {
            family_name: "STIX Two Math",
            style: "Regular",
            full_name: "STIX Two Math",
            post_script_name: "STIXTwoMath",
            version: "2.02 b142",
            description: "Arie de Ruiter, who in 1995 was Head of Information Technology Development at Elsevier Science, made a proposal to the STI Pub group, an informal group of publishers consisting of representatives from the American Chemical Society (ACS), American Institute of Physics (AIP), American Mathematical Society (AMS), American Physical Society (APS), Elsevier, and Institute of Electrical and Electronics Engineers (IEEE). De Ruiter encouraged the members to consider development of a series of Web fonts, which he proposed should be called the Scientific and Technical Information eXchange, or STIX, Fonts. All STI Pub member organizations enthusiastically endorsed this proposal, and the STI Pub group agreed to embark on what has become a twelve-year project. The goal of the project was to identify all alphabetic, symbolic, and other special characters used in any facet of scientific publishing and to create a set of Unicode-based fonts that would be distributed free to every scientist, student, and other interested party worldwide. The fonts would be consistent with the emerging Unicode standard, and would permit universal representation of every character. With the release of the STIX fonts, de Ruiter's vision has been realized.",
            filename: "STIX2Math.otf",
            copyright: "Copyright (c) 2001-2016 by the STI Pub Companies, consisting of the American Chemical Society, the American Institute of Physics, the American Mathematical Society, the American Physical Society, Elsevier, Inc., and The Institute of Electrical and Electronic Engineers, Inc.  Portions copyright (c) 1998-2003 by MicroPress, Inc.  Portions copyright (c) 1990 by Elsevier, Inc.  All rights reserved.  Portions copyright (c) Copyright 2010, 2012, 2014 Adobe Systems Incorporated.",
          },
        ]
      )

      provides_font(
        "STIX Two Text",
        match_styles_from_file: [
          {
            family_name: "STIX Two Text",
            style: "Bold Italic",
            full_name: "STIX Two Text Bold Italic",
            post_script_name: "STIXTwoText-BoldItalic",
            version: "2.02 b142",
            description: "Arie de Ruiter, who in 1995 was Head of Information Technology Development at Elsevier Science, made a proposal to the STI Pub group, an informal group of publishers consisting of representatives from the American Chemical Society (ACS), American Institute of Physics (AIP), American Mathematical Society (AMS), American Physical Society (APS), Elsevier, and Institute of Electrical and Electronics Engineers (IEEE). De Ruiter encouraged the members to consider development of a series of Web fonts, which he proposed should be called the Scientific and Technical Information eXchange, or STIX, Fonts. All STI Pub member organizations enthusiastically endorsed this proposal, and the STI Pub group agreed to embark on what has become a twelve-year project. The goal of the project was to identify all alphabetic, symbolic, and other special characters used in any facet of scientific publishing and to create a set of Unicode-based fonts that would be distributed free to every scientist, student, and other interested party worldwide. The fonts would be consistent with the emerging Unicode standard, and would permit universal representation of every character. With the release of the STIX fonts, de Ruiter's vision has been realized.",
            filename: "STIX2Text-BoldItalic.otf",
            copyright: "Copyright (c) 2001-2018 by the STI Pub Companies, consisting of the American Chemical Society, the American Institute of Physics, the American Mathematical Society, the American Physical Society, Elsevier, Inc., and The Institute of Electrical and Electronic Engineers, Inc.  Portions copyright (c) 1998-2003 by MicroPress, Inc.  Portions copyright (c) 1990 by Elsevier, Inc.  All rights reserved.",
          },
          {
            family_name: "STIX Two Text",
            style: "Italic",
            full_name: "STIX Two Text Italic",
            post_script_name: "STIXTwoText-Italic",
            version: "2.02 b142",
            description: "Arie de Ruiter, who in 1995 was Head of Information Technology Development at Elsevier Science, made a proposal to the STI Pub group, an informal group of publishers consisting of representatives from the American Chemical Society (ACS), American Institute of Physics (AIP), American Mathematical Society (AMS), American Physical Society (APS), Elsevier, and Institute of Electrical and Electronics Engineers (IEEE). De Ruiter encouraged the members to consider development of a series of Web fonts, which he proposed should be called the Scientific and Technical Information eXchange, or STIX, Fonts. All STI Pub member organizations enthusiastically endorsed this proposal, and the STI Pub group agreed to embark on what has become a twelve-year project. The goal of the project was to identify all alphabetic, symbolic, and other special characters used in any facet of scientific publishing and to create a set of Unicode-based fonts that would be distributed free to every scientist, student, and other interested party worldwide. The fonts would be consistent with the emerging Unicode standard, and would permit universal representation of every character. With the release of the STIX fonts, de Ruiter's vision has been realized.",
            filename: "STIX2Text-Italic.otf",
            copyright: "Copyright (c) 2001-2018 by the STI Pub Companies, consisting of the American Chemical Society, the American Institute of Physics, the American Mathematical Society, the American Physical Society, Elsevier, Inc., and The Institute of Electrical and Electronic Engineers, Inc.  Portions copyright (c) 1998-2003 by MicroPress, Inc.  Portions copyright (c) 1990 by Elsevier, Inc.  All rights reserved.",
          },
          {
            family_name: "STIX Two Text",
            style: "Regular",
            full_name: "STIX Two Text",
            post_script_name: "STIXTwoText",
            version: "2.02 b142",
            description: "Arie de Ruiter, who in 1995 was Head of Information Technology Development at Elsevier Science, made a proposal to the STI Pub group, an informal group of publishers consisting of representatives from the American Chemical Society (ACS), American Institute of Physics (AIP), American Mathematical Society (AMS), American Physical Society (APS), Elsevier, and Institute of Electrical and Electronics Engineers (IEEE). De Ruiter encouraged the members to consider development of a series of Web fonts, which he proposed should be called the Scientific and Technical Information eXchange, or STIX, Fonts. All STI Pub member organizations enthusiastically endorsed this proposal, and the STI Pub group agreed to embark on what has become a twelve-year project. The goal of the project was to identify all alphabetic, symbolic, and other special characters used in any facet of scientific publishing and to create a set of Unicode-based fonts that would be distributed free to every scientist, student, and other interested party worldwide. The fonts would be consistent with the emerging Unicode standard, and would permit universal representation of every character. With the release of the STIX fonts, de Ruiter's vision has been realized.",
            filename: "STIX2Text-Regular.otf",
            copyright: "Copyright (c) 2001-2018 by the STI Pub Companies, consisting of the American Chemical Society, the American Institute of Physics, the American Mathematical Society, the American Physical Society, Elsevier, Inc., and The Institute of Electrical and Electronic Engineers, Inc.  Portions copyright (c) 1998-2003 by MicroPress, Inc.  Portions copyright (c) 1990 by Elsevier, Inc.  All rights reserved.",
          },
          {
            family_name: "STIX Two Text",
            style: "Bold",
            full_name: "STIX Two Text Bold",
            post_script_name: "STIXTwoText-Bold",
            version: "2.02 b142",
            description: "Arie de Ruiter, who in 1995 was Head of Information Technology Development at Elsevier Science, made a proposal to the STI Pub group, an informal group of publishers consisting of representatives from the American Chemical Society (ACS), American Institute of Physics (AIP), American Mathematical Society (AMS), American Physical Society (APS), Elsevier, and Institute of Electrical and Electronics Engineers (IEEE). De Ruiter encouraged the members to consider development of a series of Web fonts, which he proposed should be called the Scientific and Technical Information eXchange, or STIX, Fonts. All STI Pub member organizations enthusiastically endorsed this proposal, and the STI Pub group agreed to embark on what has become a twelve-year project. The goal of the project was to identify all alphabetic, symbolic, and other special characters used in any facet of scientific publishing and to create a set of Unicode-based fonts that would be distributed free to every scientist, student, and other interested party worldwide. The fonts would be consistent with the emerging Unicode standard, and would permit universal representation of every character. With the release of the STIX fonts, de Ruiter's vision has been realized.",
            filename: "STIX2Text-Bold.otf",
            copyright: "Copyright (c) 2001-2018 by the STI Pub Companies, consisting of the American Chemical Society, the American Institute of Physics, the American Mathematical Society, the American Physical Society, Elsevier, Inc., and The Institute of Electrical and Electronic Engineers, Inc.  Portions copyright (c) 1998-2003 by MicroPress, Inc.  Portions copyright (c) 1990 by Elsevier, Inc.  All rights reserved.",
          },
        ]
      )

      def extract
        resource("stix.zip") do |resource|
          unzip(resource, fonts_sub_dir: "**/*") do |fontdir|
            match_fonts(fontdir, "STIX Two Math")
            match_fonts(fontdir, "STIX Two Text")
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/STIX"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/stix"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/STIX/STIX2Math.otf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/stix/STIX2Math.otf", :exist?
        end
      end

      open_license <<~EOS
  STIX Font License
  15 April 2019

  Copyright © 2001–2019 by the STI Pub Companies, consisting of AIP Publishing, the American Chemical Society, the American Mathematical Society, the American Physical Society, Elsevier, Inc., and The Institute of Electrical and Electronic Engineers, Inc. (www.stixfonts.org), with Reserved Font Name STIX Fonts. STIX FontsTM is a trademark of The Institute of Electrical and Electronics Engineers, Inc.

  Portions copyright © 1998–2003 by MicroPress, Inc. (www.micropress-inc.com), with Reserved Font Name TM Math. To obtain additional mathematical fonts, please contact MicroPress, Inc., 68-30 Harrow Street, Forest Hills, NY 11375, USA – Phone: (718) 575-1816.
  Portions copyright © 1990 by Elsevier, Inc.
  Portions copyright © 2010, 2012, 2014 Adobe Systems Incorporated.

  This Font Software is licensed under the SIL Open Font License, Version 1.1. This license is copied below, and is also available with a FAQ at http://scripts.sil.org/OFL.

  --------------------------------------------------
  SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
  --------------------------------------------------
  PREAMBLE

  The goals of the Open Font License (OFL) are to stimulate worldwide development of collaborative font projects, to support the font creation efforts of academic and linguistic communities, and to provide a free and open frame- work in which fonts may be shared and improved in partnership with others.

  The OFL allows the licensed fonts to be used, studied, modified and redistributed freely as long as they are not sold by themselves. The fonts, including any derivative works, can be bundled, embedded, redistributed and/or sold with any software provided that any reserved names are not used by derivative works. The fonts and derivatives, however, cannot be released under any other type of license. The requirement for fonts to remain under this license does not apply to any document created using the fonts or their derivatives.

  DEFINITIONS

  “Font Software” refers to the set of files released by the Copyright Holder(s) under this license and clearly marked as such. This may include source files, build scripts and documentation.

  “Reserved Font Name” refers to any names specified as such after the copyright statement(s).

  “Original Version” refers to the collection of Font Software components as distributed by the Copyright Holder(s).

  “Modified Version” refers to any derivative made by adding to, deleting, or substituting – in part or in whole – any of the components of the Original Version, by changing formats or by porting the Font Software to a new environment.

  “Author” refers to any designer, engineer, programmer, technical writer or other person who contributed to the Font Software.

  PERMISSION & CONDITIONS

  Permission is hereby granted, free of charge, to any person obtaining a copy of the Font Software, to use, study, copy, merge, embed, modify, redistribute, and sell modified and unmodified copies of the Font Software, subject to the following conditions:

  1) Neither the Font Software nor any of its individual components, in Original or Modified Versions, may be sold by itself.

  2) Original or Modified Versions of the Font Software may be bundled, redistributed and/or sold with any soft- ware, provided that each copy contains the above copyright notice and this license. These can be included either as stand-alone text files, human-readable headers or in the appropriate machine-readable metadata fields within text or binary files as long as those fields can be easily viewed by the user.

  3) No Modified Version of the Font Software may use the Reserved Font Name(s) unless explicit written permission is granted by the corresponding Copyright Holder. This restriction only applies to the primary font name as presented to the users.

  4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font Software shall not be used to promote, endorse or advertise any Modified Version, except to acknowledge the contribution(s) of the Copyright Holder(s) and the Author(s) or with their explicit written permission.

  5) The Font Software, modified or unmodified, in part or in whole, must be distributed entirely under this license, and must not be distributed under any other license. The requirement for fonts to remain under this license does not apply to any document created using the Font Software.

  TERMINATION

  This license becomes null and void if any of the above conditions are not met.

  DISCLAIMER

  THE FONT SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY, FIT- NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF COPYRIGHT, PATENT, TRADE- MARK, OR OTHER RIGHT. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, INCLUDING ANY GENERAL, SPECIAL, INDIRECT, IN- CIDENTAL, OR CONSEQUENTIAL DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER DEALINGS IN THE FONT SOFTWARE.

      EOS
    end 
  end
end
