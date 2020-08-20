module Fontist
  module Formulas
    class JsMathcmsy10Font < FontFormula
      FULLNAME = "jsMath cmsy10".freeze
      CLEANNAME = "jsMathcmsy10".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=jsMath%20cmsy10"
        sha256 "935790df0bd975e1b66a528e7cb032f6f625947c2980870f57ace715d0354651"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "jsMath-cmsy10",
            style: "cmsy10",
            full_name: "jsMath-cmsy10",
            post_script_name: "jsMath-cmsy10",
            version: "001.001",
            filename: "jsMath-cmsy10.ttf",
            copyright: "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/jsMath-cmsy10.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/jsMath-cmsy10.ttf", :exist?
        end
      end

      copyright "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/"
      license_url ""

      open_license <<~TEXT
      TEXT
    end
  end
end
