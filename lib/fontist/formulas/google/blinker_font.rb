module Fontist
  module Formulas
    class BlinkerFont < FontFormula
      FULLNAME = "Blinker".freeze
      CLEANNAME = "Blinker".freeze

      desc FULLNAME
      homepage "http://supertype.de"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Blinker"
        sha256 "464cf9c409438069e5093cef6c268a2e614ef205f7578ed0a8a504bf1b61e2f9"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Thin" => "Blinker-Thin.ttf",
        "ExtraLight" => "Blinker-ExtraLight.ttf",
        "Light" => "Blinker-Light.ttf",
        "Regular" => "Blinker-Regular.ttf",
        "SemiBold" => "Blinker-SemiBold.ttf",
        "Bold" => "Blinker-Bold.ttf",
        "ExtraBold" => "Blinker-ExtraBold.ttf",
        "Black" => "Blinker-Black.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Blinker-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Blinker-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2019 the Blinker project authors (https://github.com/supertype-de/Blinker)"
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
