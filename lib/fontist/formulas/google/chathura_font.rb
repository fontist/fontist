module Fontist
  module Formulas
    class ChathuraFont < FontFormula
      FULLNAME = "Chathura".freeze
      CLEANNAME = "Chathura".freeze

      desc FULLNAME
      homepage "www.adityafonts.com"

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=Chathura"
        sha256 "29e382038e3f9000ba9565fc88771a43646d0f0d05369668a2db28be7cefc17e"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Thin" => "Chathura-Thin.ttf",
        "Light" => "Chathura-Light.ttf",
        "Regular" => "Chathura-Regular.ttf",
        "Bold" => "Chathura-Bold.ttf",
        "ExtraBold" => "Chathura-ExtraBold.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/Chathura-Thin.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/Chathura-Thin.ttf", :exist?
        end
      end

      copyright "Copyright 2009 The Chathura Project Authors."
      license_url "http://scripts.sil.org/OFL"

      open_license <<~TEXT
      TEXT
    end
  end
end
