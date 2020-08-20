module Fontist
  module Formulas
    class JsMathcmr10Font < FontFormula
      FULLNAME = "jsMath cmr10".freeze
      CLEANNAME = "jsMathcmr10".freeze

      desc FULLNAME
      homepage ""

      resource "#{CLEANNAME}.zip" do
        url "https://fonts.google.com/download?family=jsMath%20cmr10"
        sha256 "b4c512a52c1d41e09c83e15a507f237fbb1a7b33183824ea7f35b7a4d77e002a"
      end

      provides_font(
        FULLNAME,
        match_styles_from_file: [
          {
            family_name: "jsMath-cmr10",
            style: "cmr10",
            full_name: "jsMath-cmr10",
            post_script_name: "jsMath-cmr10",
            version: "001.001",
            filename: "jsMath-cmr10.ttf",
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
          assert_predicate "$HOME/Library/Fonts/#{CLEANNAME}/jsMath-cmr10.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/#{CLEANNAME.downcase}/jsMath-cmr10.ttf", :exist?
        end
      end

      copyright "Generated from MetaFont bitmap by mftrace 1.0.33, http://www.cs.uu.nl/~hanwen/mftrace/"
      license_url ""

      open_license <<~TEXT
      TEXT
    end
  end
end
