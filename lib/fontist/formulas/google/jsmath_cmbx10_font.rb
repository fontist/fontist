module Fontist
  module Formulas
    class JsMathcmbx10Font < FontFormula
      FULLNAME = "jsMath cmbx10".freeze
      CLEANNAME = "jsMathcmbx10".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=jsMath%20cmbx10"
        sha256 "5bfe9a67c6effe4804dc48d3938fe04c58b5a90fb422547b1ea9680869d4830a"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "jsMath-cmbx10",
            style: "cmbx10",
            full_name: "jsMath-cmbx10",
            post_script_name: "jsMath-cmbx10",
            version: "001.001",
            filename: "jsMath-cmbx10.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/jsMath-cmbx10.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/jsMath-cmbx10.ttf", :exist?
        end
      end

      copyright "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/"
      license_url ""

      open_license <<~TEXT
      TEXT
    end
  end
end
