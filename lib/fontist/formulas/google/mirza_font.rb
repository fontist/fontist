module Fontist
  module Formulas
    class MirzaFont < FontFormula
      FULLNAME = "Mirza".freeze
      CLEANNAME = "Mirza".freeze

      desc FULLNAME
      homepage "https://github.com/Tarobish/Mirza"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Mirza"
        sha256 "1c9cef336d134ffe557103a3cf34a1d9796139619b468538c114a164aae836d8"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Mirza",
            style: "Regular",
            full_name: "Mirza Regular",
            post_script_name: "Mirza-Regular",
            version: "1.0010g",
            filename: "Mirza-Regular.ttf",
            copyright: "Copyright 2015, 2016 KB-Studio (www.k-b-studio.com|tarobish@gmail.com). Copyright 2015, 2016 Lasse Fister (lasse@graphicore.de). Copyright 2015, 2016 Eduardo Tunni(edu@tipo.net.ar).",
          },
          {
            family_name: "Mirza",
            style: "Medium",
            full_name: "Mirza Medium",
            post_script_name: "Mirza-Medium",
            version: "1.0010g",
            filename: "Mirza-Medium.ttf",
            copyright: "Copyright 2015, 2016 KB-Studio (www.k-b-studio.com|tarobish@gmail.com). Copyright 2015, 2016 Lasse Fister (lasse@graphicore.de). Copyright 2015, 2016 Eduardo Tunni(edu@tipo.net.ar).",
          },
          {
            family_name: "Mirza",
            style: "SemiBold",
            full_name: "Mirza SemiBold",
            post_script_name: "Mirza-SemiBold",
            version: "1.0010g",
            filename: "Mirza-SemiBold.ttf",
            copyright: "Copyright 2015, 2016 KB-Studio (www.k-b-studio.com|tarobish@gmail.com). Copyright 2015, 2016 Lasse Fister (lasse@graphicore.de). Copyright 2015, 2016 Eduardo Tunni(edu@tipo.net.ar).",
          },
          {
            family_name: "Mirza",
            style: "Bold",
            full_name: "Mirza Bold",
            post_script_name: "Mirza-Bold",
            version: "1.0010g",
            filename: "Mirza-Bold.ttf",
            copyright: "Copyright 2015, 2016 KB-Studio (www.k-b-studio.com|tarobish@gmail.com). Copyright 2015, 2016 Lasse Fister (lasse@graphicore.de). Copyright 2015, 2016 Eduardo Tunni(edu@tipo.net.ar).",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Mirza-Regular.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Mirza-Regular.ttf", :exist?
        end
      end

      copyright "Copyright 2015, 2016 KB-Studio (www.k-b-studio.com|tarobish@gmail.com). Copyright 2015, 2016 Lasse Fister (lasse@graphicore.de). Copyright 2015, 2016 Eduardo Tunni(edu@tipo.net.ar)."
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
