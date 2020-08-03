module Fontist
  module Formulas
    class ClearTypeFonts < Fontist::FontFormula
      key :cleartype
      desc "Microsoft ClearType Fonts"
      homepage "https://www.microsoft.com"

      display_progress_bar(true)
      resource "PowerPointViewer.exe" do
        urls [
          "https://gitlab.com/fontmirror/archive/-/raw/master/PowerPointViewer.exe",
          "https://nchc.dl.sourceforge.net/project/mscorefonts2/cabs/PowerPointViewer.exe",
          "https://sourceforge.net/projects/mscorefonts2/files/cabs/PowerPointViewer.exe/download",
          "https://web.archive.org/web/20171225132744/http://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe",
          "https://archive.org/download/PowerPointViewer_201801/PowerPointViewer.exe"
        ]

        sha256 [
          "249473568eba7a1e4f95498acba594e0f42e6581add4dead70c1dfb908a09423",
          "c4e753548d3092ffd7dd3849105e0a26d9b5a1afe46e6e667fe7c6887893701f",
        ]

        file_size "62914560"
      end

      provides_font_collection do |coll|
        filename "CAMBRIA.TTC"
        provides_font "Cambria", extract_styles_from_collection: {
          "Regular" => "Cambria"
        }
        provides_font "Cambria Math"
      end

      provides_font_collection do |coll|
        filename "MEIRYO.TTC"
        provides_font "Meiryo", extract_styles_from_collection: {
          "Regular" => "Meiryo",
          "Italic" => "Meiryo Italic"
        }

        provides_font "Meiryo UI", extract_styles_from_collection: {
          "Regular" => "Meiryo UI",
          "Italic" => "Meiryo UI Italic"
        }
      end

      provides_font_collection("Meiryo Bold") do |coll|
        filename "MEIRYOB.TTC"
        provides_font "Meiryo", extract_styles_from_collection: {
          "Bold" => "Meiryo Bold",
          "Bold Italic" => "Meiryo Bold Italic"
        }

        provides_font "Meiryo UI", extract_styles_from_collection: {
          "Bold" => "Meiryo UI Bold",
          "Bold Italic" => "Meiryo UI Bold Italic"
        }
      end

      provides_font("Cambria", match_styles_from_file: {
        "Bold" => "CAMBRIAB.TTF",
        "Italic" => "CAMBRIAI.TTF",
        "Bold Italic" => "CAMBRIAZ.TTF",
      })

      provides_font("Calibri", match_styles_from_file: {
        "Regular" => "CALIBRI.TTF",
        "Bold" => "CALIBRIB.TTF",
        "Italic" => "CALIBRII.TTF",
        "Bold Italic" => "CALIBRIZ.TTF"
      })

      provides_font("Candara", match_styles_from_file: {
        "Regular" => "CANDARA.TTF",
        "Bold" => "CANDARAB.TTF",
        "Italic" => "CANDARAI.TTF",
        "Bold Italic" => "CANDARAZ.TTF"
      })

      provides_font("Consola", match_styles_from_file: {
        "Regular" => "CONSOLA.TTF",
        "Bold" => "CONSOLAB.TTF",
        "Italic" => "CONSOLAI.TTF",
        "Bold Italic" => "CONSOLAZ.TTF"
      })

      provides_font("Constantia", match_styles_from_file: {
        "Regular" => "CONSTAN.TTF",
        "Bold" => "CONSTANB.TTF",
        "Italic" => "CONSTANI.TTF",
        "Bold Italic" => "CONSTANZ.TTF"
      })

      provides_font("Corbel", match_styles_from_file: {
        "Regular" => "CORBEL.TTF",
        "Bold" => "CORBELB.TTF",
        "Italic" => "CORBELI.TTF",
        "Bold Italic" => "CORBELZ.TTF"
      })

      def extract
        resource("PowerPointViewer.exe") do |resource|
          exe_extract(resource) do |dir|
            cab_extract(dir["ppviewer.cab"]) do |fontdir|
              match_fonts(fontdir, "Calibri")
              match_fonts(fontdir, "Cambria")
              match_fonts(fontdir, "Candara")
              match_fonts(fontdir, "Consola")
              match_fonts(fontdir, "Constantia")
              match_fonts(fontdir, "Corbel")
              match_fonts(fontdir, "Meiryo")
              match_fonts(fontdir, "Meiryo UI")
            end
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/Microsoft"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/cleartype"
        end
      end

      def caveats
        "Show caveats here"
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/Microsoft/candarab.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/cleartype/candarab.ttf", :exist?
        end
      end

      requires_license_agreement <<~EOS
  MICROSOFT SOFTWARE LICENSE TERMS
  MICROSOFT POWERPOINT VIEWER
  These license terms are an agreement between Microsoft Corporation (or based on where you live, one of its affiliates) and you. Please read them. They apply to the software named above, which includes the media on which you received it, if any. The terms also apply to any Microsoft

  * updates,
  * supplements,
  * Internet-based services, and
  * support services

  for this software, unless other terms accompany those items. If so, those terms apply.

  BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS. IF YOU DO NOT ACCEPT THEM, DO NOT USE THE SOFTWARE.

  If you comply with these license terms, you have the rights below.

  1.    INSTALLATION AND USE RIGHTS.

  a.    General. You may install and use any number of copies of the software on your devices. You may use the software only to view and print files created with Microsoft Office software. You may not use the software for any other purpose.

  b.    Distribution. You may copy and distribute the software, provided that:

  * each copy is complete and unmodified, including presentation of this agreement for each user's acceptance; and
  * you indemnify, defend, and hold harmless Microsoft and its affiliates and suppliers from any claims, including attorneys  fees, related to your distribution of the software.

  You may not:

  * distribute the software with any non-Microsoft software that may use the software to enhance its functionality,
  * alter any copyright, trademark or patent notices in the software,
  * use Microsoft s or affiliates or suppliers  name, logo or trademarks to market your products or services,
  * distribute the software with malicious, deceptive or unlawful programs, or
  * modify or distribute the software so that any part of it becomes subject to an Excluded License. An Excluded License is one that requires, as a condition of use, modification or distribution, that
  * the code be disclosed or distributed in source code form; or
  * others have the right to modify it.

  2.    SCOPE OF LICENSE. The software is licensed, not sold. This agreement only gives you some rights to use the software. Microsoft reserves all other rights. Unless applicable law gives you more rights despite this limitation, you may use the software only as expressly permitted in this agreement. In doing so, you must comply with any technical limitations in the software that only allow you to use it in certain ways. You may not

  * work around any technical limitations in the software;
  * reverse engineer, decompile or disassemble the software, except and only to the extent that applicable law expressly permits, despite this limitation;
  * make more copies of the software than specified in this agreement or allowed by applicable law, despite this limitation;
  * publish the software for others to copy;
  * rent, lease or lend the software; or
  * use the software for commercial software hosting services.

  3.    BACKUP COPY. You may make one backup copy of the software. You may use it only to reinstall the software.

  4.    FONT COMPONENTS. While the software is running, you may use its fonts to display and print content. You may only

  * embed fonts in content as permitted by the embedding restrictions in the fonts; and
  * temporarily download them to a printer or other output device to print content.

  5.    DOCUMENTATION. Any person that has valid access to your computer or internal network may copy and use the documentation for your internal, reference purposes.

  6.    TRANSFER TO ANOTHER DEVICE. You may uninstall the software and install it on another device for your use. You may not do so to share this license between devices.

  7.    TRANSFER TO A THIRD PARTY. The first user of the software may transfer it and this agreement directly to a third party. Before the transfer, that party must agree that this agreement applies to the transfer and use of the software. The first user must uninstall the software before transferring it separately from the device. The first user may not retain any copies.

  8.    EXPORT RESTRICTIONS. The software is subject to United States export laws and regulations. You must comply with all domestic and international export laws and regulations that apply to the software. These laws include restrictions on destinations, end users and end use. For additional information, see www.microsoft.com/exporting.

  9.    SUPPORT SERVICES. Because this software is  as is,  we may not provide support services for it.

  10.    ENTIRE AGREEMENT. This agreement, and the terms for supplements, updates, Internet-based services and support services that you use, are the entire agreement for the software and support services.

  11.    APPLICABLE LAW.

  a.    United States. If you acquired the software in the United States, Washington state law governs the interpretation of this agreement and applies to claims for breach of it, regardless of conflict of laws principles. The laws of the state where you live govern all other claims, including claims under state consumer protection laws, unfair competition laws, and in tort.

  b.    Outside the United States. If you acquired the software in any other country, the laws of that country apply.

  12.    LEGAL EFFECT. This agreement describes certain legal rights. You may have other rights under the laws of your country. You may also have rights with respect to the party from whom you acquired the software. This agreement does not change your rights under the laws of your country if the laws of your country do not permit it to do so.

  13.    DISCLAIMER OF WARRANTY. THE SOFTWARE IS LICENSED  AS-IS.  YOU BEAR THE RISK OF USING IT. MICROSOFT GIVES NO EXPRESS WARRANTIES, GUARANTEES OR CONDITIONS. YOU MAY HAVE ADDITIONAL CONSUMER RIGHTS UNDER YOUR LOCAL LAWS WHICH THIS AGREEMENT CANNOT CHANGE. TO THE EXTENT PERMITTED UNDER YOUR LOCAL LAWS, MICROSOFT EXCLUDES THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.

  14.    LIMITATION ON AND EXCLUSION OF REMEDIES AND DAMAGES. YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00. YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT OR INCIDENTAL DAMAGES.

  This limitation applies to

  * anything related to the software, services, content (including code) on third party Internet sites, or third party programs; and
  * claims for breach of contract, breach of warranty, guarantee or condition, strict liability, negligence, or other tort to the extent permitted by applicable law.

  It also applies even if Microsoft knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your country may not allow the exclusion or limitation of incidental, consequential or other damages.

  EULAID:O14_RTM_PPV.1_RTM_EN

      EOS
    end
  end
end
