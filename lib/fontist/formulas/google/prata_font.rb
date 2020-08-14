module Fontist
  module Formulas
    class PrataFont < FontFormula
      FULLNAME = "Prata".freeze
      CLEANNAME = "Prata".freeze

      desc FULLNAME
      homepage "http://www.cyreal.org"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Prata"
        sha256 "7cbdf0e63bc68df70d73488610c85dce078b9a769aa5bd0029dd9ec100266710"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Regular" => "Prata-Regular.ttf",
      })

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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Prata-Regular.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Prata-Regular.ttf", :exist?
        end
      end

      copyright "Copyright 2011 The Prata Project Authors (contact@cyreal.org)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
