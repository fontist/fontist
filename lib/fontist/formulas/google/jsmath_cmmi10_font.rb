module Fontist
  module Formulas
    class JsMathcmmi10Font < FontFormula
      FULLNAME = "jsMath cmmi10".freeze
      CLEANNAME = "jsMathcmmi10".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=jsMath%20cmmi10"
        sha256 "340d23662694ec27b9836eaf3d1cfa7d3e89a1520838102e7f49108053cd1266"
      end

      provides_font(FULLNAME, match_styles_from_file: {
        "Regular" => "jsMath-cmmi10.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/jsMath-cmmi10.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/jsMath-cmmi10.ttf", :exist?
        end
      end

      copyright "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/"
      license_url ""

      open_license <<~TEXT
      TEXT
    end
  end
end
