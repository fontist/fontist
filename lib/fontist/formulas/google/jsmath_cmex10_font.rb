module Fontist
  module Formulas
    class JsMathcmex10Font < FontFormula
      FULLNAME = "jsMath cmex10".freeze
      CLEANNAME = "jsMathcmex10".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=jsMath%20cmex10"
        sha256 "136b41193cdfe13f7bdc7b1883b2a75213e065a92d41a1c74b71e75f1a27675f"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Regular" => "jsMath-cmex10.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/jsMath-cmex10.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/jsMath-cmex10.ttf", :exist?
        end
      end

      copyright "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/"
      license_url ""

      open_license <<~TEXT
      TEXT
    end
  end
end
