module Fontist
  module Formulas
    class SegoeUiFont < FontFormula
      desc "Microsoft Segoe UI Font"
      homepage "https://www.microsoft.com"

      # English version
      # resource "ExcelViewer.exe" do
      #   urls [
      #     "https://web.archive.org/web/20171225133033if_/http://download.microsoft.com/download/e/a/9/ea913c8b-51a7-41b7-8697-9f0d0a7274aa/ExcelViewer.exe",
      #
      #     "https://msassist.com/files/MSOffice/Compatibility/ExcelViewer.exe"
      #   ]
      #   sha256 "4fc8e08237e8b458091c83dde68139e779fe401b4884d92d66ec843b5ca4a2ca"
      # end

      # German version
      resource "ExcelViewer.exe" do
        urls [
          "https://web.archive.org/web/20170104231942if_/http://download.microsoft.com/download/F/8/8/F88CB355-ECAA-4B74-87D6-C05C81D215BF/ExcelViewer.exe"
        ]
        sha256 "56e2fcd583ffaaa316257de7b208e6be411c4e343b7e4072c95053baa11539af"
      end

      provides_font("Segoe UI", match_styles_from_file: {
        "Regular" => "SEGOEUI.TTF",
        "Italic" => "SEGOEUII.TTF",
        "Bold" => "SEGOEUIB.TTF",
        "Bold Italic" => "SEGOEUIZ.TTF"
      })

      def extract
        resource "ExcelViewer.exe" do |resource|
          exe_extract(resource) do |dir|
            cab_extract(dir["xlview.msi"]) do |dir2|
              cab_extract(dir2['XLVIEW.CAB']) do |fontdir|
                match_fonts(fontdir, "Segoe UI")
              end
            end
          end
        end

        # resource("wd97vwr32.exe") do |resource|
        #   cab_extract(resource) do |dir|
        #     cab_extract(dir['xlview.msi']) do |fontdir|
        #       cab_extract(dir['XLVIEW.CAB']) do |fontdir|
        #         match_fonts(fontdir, "Segoe UI")
        #       end
        #     end
        #   end
        # end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/Microsoft"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/microsoft"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/Microsoft/segoeui.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/microsoft/segoeui.ttf", :exist?
        end
      end

      requires_license_agreement <<~EOS
  MICROSOFT SOFTWARE LICENSE TERMS
  MICROSOFT OFFICE EXCEL VIEWER

  These license terms are an agreement between Microsoft Corporation (or based on where you live, one of its affiliates) and you.  Please read them.  They apply to the software named above, which includes the media on which you received it, if any.  The terms also apply to any Microsoft

  * updates,
  * supplements,
  * Internet-based services, and
  * support services

  for this software, unless other terms accompany those items.  If so, those terms apply.

  BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS.  IF YOU DO NOT ACCEPT THEM, DO NOT USE THE SOFTWARE.

  If you comply with these license terms, you have the rights below.

  1. INSTALLATION AND USE RIGHTS.

  a. General.  You may install and use any  number of copies of the software on your devices.  You may use the software only to view and print files created with Microsoft Office software.  You may not use the software for any other purpose.

  b. Distribution.  You may copy and distribute the software, provided that:

  *  each copy is complete and unmodified, including presentation of this agreement for each user's acceptance; and
  *  you indemnify, defend, and hold harmless Microsoft and its affiliates and suppliers from any claims, including attorneys' fees, related to your distribution of the software.

  You may not:

  *  distribute the software with any non-Microsoft software that may use the software to enhance its functionality,
  *  alter any copyright, trademark or patent notices in the software,
  *  use Microsoft's or affiliates or suppliers' name, logo or trademarks to market your products or services,
  *  distribute the software with malicious, deceptive or unlawful programs, or
  *  modify or distribute the software so that any part of it becomes subject to an Excluded License.  An Excluded License is one that requires, as a condition of use, modification or distribution, that
  *  the code be disclosed or distributed in source code form; or
  *  others have the right to modify it.

  2. SCOPE OF LICENSE.  The software is licensed, not sold. This agreement only gives you some rights to use the software.  Microsoft reserves all other rights.  Unless applicable law gives you more rights despite this limitation, you may use the software only as expressly permitted in this agreement.  In doing so, you must comply with any technical limitations in the software that only allow you to use it in certain ways.    You may not

  *  work around any technical limitations in the software;
  *  reverse engineer, decompile or disassemble the software, except and only to the extent that applicable law expressly permits, despite this limitation;
  *  make more copies of the software than specified in this agreement or allowed by applicable law, despite this limitation;
  *  publish the software for others to copy;
  *  rent, lease or lend the software; or
  *  use the software for commercial software hosting services.

  3. BACKUP COPY.  You may make one backup copy of the software.  You may use it only to reinstall the software.

  4. DOCUMENTATION.  Any person that has valid access to your computer or internal network may copy and use the documentation for your internal, reference purposes.

  5. TRANSFER TO ANOTHER DEVICE.  You may uninstall the software and install it on another device for your use.  You may not do so to share this license between devices.

  6. EXPORT RESTRICTIONS.  The software is subject to United States export laws and regulations.  You must comply with all domestic and international export laws and regulations that apply to the software.  These laws include restrictions on destinations, end users and end use.  For additional information, see www.microsoft.com/exporting.

  7. SUPPORT SERVICES. Because this software is "as is," we may not provide support services for it.

  8. ENTIRE AGREEMENT.  This agreement, and the terms for supplements, updates, Internet-based services and support services that you use, are the entire agreement for the software and support services.

  9. APPLICABLE LAW.

  a. United States.  If you acquired the software in the United States, Washington state law governs the interpretation of this agreement and applies to claims for breach of it, regardless of conflict of laws principles.  The laws of the state where you live govern all other claims, including claims under state consumer protection laws, unfair competition laws, and in tort.

  b. Outside the United States.  If you acquired the software in any other country, the laws of that country apply.

  10. LEGAL EFFECT.  This agreement describes certain legal rights.  You may have other rights under the laws of your country.  You may also have rights with respect to the party from whom you acquired the software.  This agreement does not change your rights under the laws of your country if the laws of your country do not permit it to do so.

  11. DISCLAIMER OF WARRANTY.   THE SOFTWARE IS LICENSED " AS-IS."   YOU BEAR THE RISK OF USING IT.  MICROSOFT GIVES NO EXPRESS WARRANTIES, GUARANTEES OR CONDITIONS.  YOU MAY HAVE ADDITIONAL CONSUMER RIGHTS UNDER YOUR LOCAL LAWS WHICH THIS AGREEMENT CANNOT CHANGE.  TO THE EXTENT PERMITTED UNDER YOUR LOCAL LAWS, MICROSOFT EXCLUDES THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.

  12. LIMITATION ON AND EXCLUSION OF REMEDIES AND DAMAGES.  YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00.  YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT OR INCIDENTAL DAMAGES.

  This limitation applies to

  *  anything related to the software, services, content (including code) on third party Internet sites, or third party programs; and

  *  claims for breach of contract, breach of warranty, guarantee or condition, strict liability, negligence, or other tort to the extent permitted by applicable law.

  It also applies even if Microsoft knew or should have known about the possibility of the damages.  The above limitation or exclusion may not apply to you because your country may not allow the exclusion or limitation of incidental, consequential or other damages.

  EULAID:O12_RTM_VWR.0_ALL_EN
      EOS
    end
  end
end
