module Fontist
  module Formulas
    class CourierFont < FontFormula
      desc "Microsoft TrueType Core fonts for the Web"
      homepage "https://www.microsoft.com"

      resource "courie32.exe" do
        urls [
          "https://gitlab.com/fontmirror/archive/-/raw/master/courie32.exe",
          "https://nchc.dl.sourceforge.net/project/corefonts/the%20fonts/final/courie32.exe",
          "http://sft.if.usp.br/msttcorefonts/courie32.exe"
        ]
        sha256 "bb511d861655dde879ae552eb86b134d6fae67cb58502e6ff73ec5d9151f3384"
      end

      provides_font(
        "Courier",
        match_styles_from_file: [
          {
            family_name: "Courier New",
            style: "Regular",
            full_name: "Courier New",
            post_script_name: "CourierNewPSMT",
            version: "2.82",
            description: "Designed as a typewriter face for IBM, Courier was re drawn by Adrian Frutiger for IBM Selectric series.  A typical fixed pitch design, monotone in weight and slab serif in concept.  Used to emulate typewriter output for reports, tabular work and technical documentation.",
            filename: "cour.ttf",
            copyright: "Typeface © The Monotype Corporation plc. Data © The Monotype Corporation plc/Type Solutions Inc. 1990-1994. All Rights Reserved",
          },
          {
            family_name: "Courier New",
            style: "Bold",
            full_name: "Courier New Bold",
            post_script_name: "CourierNewPS-BoldMT",
            version: "2.82",
            description: "Designed as a typewriter face for IBM, Courier was re drawn by Adrian Frutiger for IBM Selectric series.  A typical fixed pitch design, monotone in weight and slab serif in concept.  Used to emulate typewriter output for reports, tabular work and technical documentation.",
            filename: "courbd.ttf",
            copyright: "Typeface © The Monotype Corporation plc. Data © The Monotype Corporation plc/Type Solutions Inc. 1990-1992. All Rights Reserved",
          },
          {
            family_name: "Courier New",
            style: "Bold Italic",
            full_name: "Courier New Bold Italic",
            post_script_name: "CourierNewPS-BoldItalicMT",
            version: "2.82",
            description: "Designed as a typewriter face for IBM, Courier was re drawn by Adrian Frutiger for IBM Selectric series.  A typical fixed pitch design, monotone in weight and slab serif in concept.  Used to emulate typewriter output for reports, tabular work and technical documentation.",
            filename: "courbi.ttf",
            copyright: "Typeface © The Monotype Corporation plc. Data © The Monotype Corporation plc/Type Solutions Inc. 1990-1992. All Rights Reserved",
          },
          {
            family_name: "Courier New",
            style: "Italic",
            full_name: "Courier New Italic",
            post_script_name: "CourierNewPS-ItalicMT",
            version: "2.82",
            description: "Designed as a typewriter face for IBM, Courier was re drawn by Adrian Frutiger for IBM Selectric series.  A typical fixed pitch design, monotone in weight and slab serif in concept.  Used to emulate typewriter output for reports, tabular work and technical documentation.",
            filename: "couri.ttf",
            copyright: "Typeface © The Monotype Corporation plc. Data © The Monotype Corporation plc/Type Solutions Inc. 1990-1992. All Rights Reserved",
          },
        ]
      )

      def extract
        resource "courie32.exe" do |resource|
          cab_extract(resource) do |dir|
            match_fonts(dir, "Courier")
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/Microsoft"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/vista"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/Microsoft/cour.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/vista/cour.ttf", :exist?
        end
      end

      requires_license_agreement <<~EOS
  (from http://web.archive.org/web/20011222020409/http://www.microsoft.com/typography/fontpack/eula.htm)
  TrueType core fonts for the Web EULA
  END-USER LICENSE AGREEMENT FOR
  MICROSOFT SOFTWARE
  IMPORTANT-READ CAREFULLY: This Microsoft End-User License Agreement ("EULA") is a legal agreement between you (either an individual or a single entity) and Microsoft Corporation for the Microsoft software accompanying this EULA, which includes computer software and may include associated media, printed materials, and "on-line" or electronic documentation ("SOFTWARE PRODUCT" or "SOFTWARE"). By exercising your rights to make and use copies of the SOFTWARE PRODUCT, you agree to be bound by the terms of this EULA. If you do not agree to the terms of this EULA, you may not use the SOFTWARE PRODUCT.
  SOFTWARE PRODUCT LICENSE
  The SOFTWARE PRODUCT is protected by copyright laws and international copyright treaties, as well as other intellectual property laws and treaties. The SOFTWARE PRODUCT is licensed, not sold.
  1. GRANT OF LICENSE. This EULA grants you the following rights:
  * Installation and Use. You may install and use an unlimited number of copies of the SOFTWARE PRODUCT.
  * Reproduction and Distribution. You may reproduce and distribute an unlimited number of copies of the SOFTWARE PRODUCT; provided that each copy shall be a true and complete copy, including all copyright and trademark notices, and shall be accompanied by a copy of this EULA. Copies of the SOFTWARE PRODUCT may not be distributed for profit either on a standalone basis or included as part of your own product.
  2. DESCRIPTION OF OTHER RIGHTS AND LIMITATIONS.
  * Limitations on Reverse Engineering, Decompilation, and Disassembly. You may not reverse engineer, decompile, or disassemble the SOFTWARE PRODUCT, except and only to the extent that such activity is expressly permitted by applicable law notwithstanding this limitation.
  * Restrictions on Alteration. You may not rename, edit or create any derivative works from the SOFTWARE PRODUCT, other than subsetting when embedding them in documents.
  * Software Transfer. You may permanently transfer all of your rights under this EULA, provided the recipient agrees to the terms of this EULA.
  * Termination. Without prejudice to any other rights, Microsoft may terminate this EULA if you fail to comply with the terms and conditions of this EULA. In such event, you must destroy all copies of the SOFTWARE PRODUCT and all of its component parts.
  3. COPYRIGHT. All title and copyrights in and to the SOFTWARE PRODUCT (including but not limited to any images, text, and "applets" incorporated into the SOFTWARE PRODUCT), the accompanying printed materials, and any copies of the SOFTWARE PRODUCT are owned by Microsoft or its suppliers. The SOFTWARE PRODUCT is protected by copyright laws and international treaty provisions. Therefore, you must treat the SOFTWARE PRODUCT like any other copyrighted material.
  4. U.S. GOVERNMENT RESTRICTED RIGHTS. The SOFTWARE PRODUCT and documentation are provided with RESTRICTED RIGHTS. Use, duplication, or disclosure by the Government is subject to restrictions as set forth in subparagraph (c)(1)(ii) of the Rights in Technical Data and Computer Software clause at DFARS 252.227-7013 or subparagraphs (c)(1) and (2) of the Commercial Computer Software - Restricted Rights at 48 CFR 52.227-19, as applicable. Manufacturer is Microsoft Corporation/One Microsoft Way/Redmond, WA 98052-6399.
  LIMITED WARRANTY
  NO WARRANTIES. Microsoft expressly disclaims any warranty for the SOFTWARE PRODUCT. The SOFTWARE PRODUCT and any related documentation is provided "as is" without warranty of any kind, either express or implied, including, without limitation, the implied warranties or merchantability, fitness for a particular purpose, or noninfringement. The entire risk arising out of use or performance of the SOFTWARE PRODUCT remains with you.
  NO LIABILITY FOR CONSEQUENTIAL DAMAGES. In no event shall Microsoft or its suppliers be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or any other pecuniary loss) arising out of the use of or inability to use this Microsoft product, even if Microsoft has been advised of the possibility of such damages. Because some states/jurisdictions do not allow the exclusion or limitation of liability for consequential or incidental damages, the above limitation may not apply to you.
  MISCELLANEOUS
  If you acquired this product in the United States, this EULA is governed by the laws of the State of Washington.
  If this product was acquired outside the United States, then local laws may apply.
  Should you have any questions concerning this EULA, or if you desire to contact Microsoft for any reason, please contact the Microsoft subsidiary serving your country, or write: Microsoft Sales Information Center/One Microsoft Way/Redmond, WA 98052-6399.
  this page was last updated 28 July 1998
  © 1997 Microsoft Corporation. All rights reserved. Terms of use.
  comments to the MST group: ttwsite@microsoft.com
      EOS
    end
  end

end
