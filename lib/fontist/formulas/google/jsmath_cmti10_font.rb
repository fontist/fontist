module Fontist
  module Formulas
    class JsMathcmti10Font < FontFormula
      FULLNAME = "jsMath cmti10".freeze
      CLEANNAME = "jsMathcmti10".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=jsMath%20cmti10"
        sha256 "4fc312b619e6a2f7319905711fc80c908c72def16f47b3441bc60cac3d29c2e6"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "jsMath-cmti10",
            style: "cmti10",
            full_name: "jsMath-cmti10",
            post_script_name: "jsMath-cmti10",
            version: "001.001",
            filename: "jsMath-cmti10.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/jsMath-cmti10.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/jsMath-cmti10.ttf", :exist?
        end
      end

      copyright "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/"
      license_url ""

      open_license <<~TEXT
      TEXT
    end
  end
end
