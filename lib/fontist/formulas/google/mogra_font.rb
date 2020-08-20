module Fontist
  module Formulas
    class MograFont < FontFormula
      FULLNAME = "Mogra".freeze
      CLEANNAME = "Mogra".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Mogra"
        sha256 "77b4f661f11bc2627140f8aea765bd3bb6517f150fafc9b0637c3a1b475c55d4"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "Mogra",
            style: "Regular",
            full_name: "Mogra Regular",
            post_script_name: "Mogra-Regular",
            version: "1.002",
            filename: "Mogra-Regular.ttf",
            copyright: "Copyright (c) 2015 Lipi Raval (raval.lipi@gmail.com)",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Mogra-Regular.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Mogra-Regular.ttf", :exist?
        end
      end

      copyright "Copyright (c) 2015 Lipi Raval (raval.lipi@gmail.com)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
