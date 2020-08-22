module Fontist
  module Formulas
    class MitrFont < FontFormula
      FULLNAME = "Mitr".freeze
      CLEANNAME = "Mitr".freeze

      desc FULLNAME
      homepage "www.cadsondemak.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Mitr"
        sha256 "e29dad193f5dcc8bb9c6b118db16ea6e7967945d380b29bfc00583b687e45b48"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Mitr",
            style: "ExtraLight",
            full_name: "Mitr ExtraLight",
            post_script_name: "Mitr-ExtraLight",
            version: "1.001",
            filename: "Mitr-ExtraLight.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Mitr",
            style: "Light",
            full_name: "Mitr Light",
            post_script_name: "Mitr-Light",
            version: "1.003",
            filename: "Mitr-Light.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Mitr",
            style: "Regular",
            full_name: "Mitr Regular",
            post_script_name: "Mitr-Regular",
            version: "1.003",
            filename: "Mitr-Regular.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Mitr",
            style: "Medium",
            full_name: "Mitr Medium",
            post_script_name: "Mitr-Medium",
            version: "1.003",
            filename: "Mitr-Medium.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Mitr",
            style: "SemiBold",
            full_name: "Mitr SemiBold",
            post_script_name: "Mitr-SemiBold",
            version: "1.003",
            filename: "Mitr-SemiBold.ttf",
            copyright: "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)",
          },
          {
            family_name: "Mitr",
            style: "Bold",
            full_name: "Mitr Bold",
            post_script_name: "Mitr-Bold",
            version: "1.003",
            filename: "Mitr-Bold.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Mitr-ExtraLight.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Mitr-ExtraLight.ttf", :exist?
        end
      end

      copyright "Copyright (c) 2015, Cadson Demak (info@cadsondemak.com)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
