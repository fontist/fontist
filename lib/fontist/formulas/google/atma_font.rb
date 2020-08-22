module Fontist
  module Formulas
    class AtmaFont < FontFormula
      FULLNAME = "Atma".freeze
      CLEANNAME = "Atma".freeze

      desc FULLNAME
      homepage "www.black-foundry.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Atma"
        sha256 "e57b5218c3ebb43f6e481a3cc83105af52c5851077dd2eff8dd52a9761a10499"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Atma",
            style: "Light",
            full_name: "Atma Light",
            post_script_name: "Atma-Light",
            version: "1.102;PS 1.100;hotconv 1.0.86;makeotf.lib2.5.63406",
            filename: "Atma-Light.ttf",
            copyright: "Copyright 2015 The Atma Project Authors (www.black-foundry.com)",
          },
          {
            family_name: "Atma",
            style: "Regular",
            full_name: "Atma Regular",
            post_script_name: "Atma-Regular",
            version: "1.102;PS 1.100;hotconv 1.0.86;makeotf.lib2.5.63406",
            filename: "Atma-Regular.ttf",
            copyright: "Copyright 2015 The Atma Project Authors (www.black-foundry.com)",
          },
          {
            family_name: "Atma",
            style: "Medium",
            full_name: "Atma Medium",
            post_script_name: "Atma-Medium",
            version: "1.102;PS 1.100;hotconv 1.0.86;makeotf.lib2.5.63406",
            filename: "Atma-Medium.ttf",
            copyright: "Copyright 2015 The Atma Project Authors (www.black-foundry.com)",
          },
          {
            family_name: "Atma",
            style: "SemiBold",
            full_name: "Atma SemiBold",
            post_script_name: "Atma-SemiBold",
            version: "1.102;PS 1.100;hotconv 1.0.86;makeotf.lib2.5.63406",
            filename: "Atma-SemiBold.ttf",
            copyright: "Copyright 2015 The Atma Project Authors (www.black-foundry.com)",
          },
          {
            family_name: "Atma",
            style: "Bold",
            full_name: "Atma Bold",
            post_script_name: "Atma-Bold",
            version: "1.102;PS 1.100;hotconv 1.0.86;makeotf.lib2.5.63406",
            filename: "Atma-Bold.ttf",
            copyright: "Copyright 2015 The Atma Project Authors (www.black-foundry.com)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Atma-Light.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Atma-Light.ttf", :exist?
        end
      end

      copyright "Copyright 2015 The Atma Project Authors (www.black-foundry.com)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
