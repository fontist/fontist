module Fontist
  module Formulas
    class MarkaziTextFont < FontFormula
      FULLNAME = "Markazi Text".freeze
      CLEANNAME = "MarkaziText".freeze

      desc FULLNAME
      homepage "http://www.borna.design, http://www.florianrunge.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Markazi%20Text"
        # sha256 "" # file changes between downloads
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Regular" => "MarkaziText[wght].ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/MarkaziText[wght].ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/MarkaziText[wght].ttf", :exist?
        end
      end

      copyright "Copyright 2017 The Markazi Text Authors (https://github.com/BornaIz/markazitext)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
