module Fontist
  module Formulas
    class SourceFonts < FontFormula
      desc "Adobe Source Fonts"
      homepage "https://www.adobe.com"

      resource "source-fonts.zip" do
        url "https://github.com/fontist/source-fonts/releases/download/v1.0/source-fonts-1.0.zip"
        sha256 "0107b5d4ba305cb4dff2ba19138407aa2153632a2c41592f74d20cd0d0261bfd"
      end

      provides_font(
        "Source Code Pro",
        match_styles_from_file: [
          {
            family_name: "Source Code Pro",
            style: "Regular",
            full_name: "Source Code Pro",
            post_script_name: "SourceCodePro-Regular",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Regular.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Medium Italic",
            full_name: "Source Code Pro Medium Italic",
            post_script_name: "SourceCodePro-MediumIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-MediumIt.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Italic",
            full_name: "Source Code Pro Italic",
            post_script_name: "SourceCodePro-It",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-It.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "ExtraLight Italic",
            full_name: "Source Code Pro ExtraLight Italic",
            post_script_name: "SourceCodePro-ExtraLightIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-ExtraLightIt.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "ExtraLight",
            full_name: "Source Code Pro ExtraLight",
            post_script_name: "SourceCodePro-ExtraLight",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-ExtraLight.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Black Italic",
            full_name: "Source Code Pro Black Italic",
            post_script_name: "SourceCodePro-BlackIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-BlackIt.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Bold Italic",
            full_name: "Source Code Pro Bold Italic",
            post_script_name: "SourceCodePro-BoldIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-BoldIt.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Semibold Italic",
            full_name: "Source Code Pro Semibold Italic",
            post_script_name: "SourceCodePro-SemiboldIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-SemiboldIt.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Black",
            full_name: "Source Code Pro Black",
            post_script_name: "SourceCodePro-Black",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Black.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Bold",
            full_name: "Source Code Pro Bold",
            post_script_name: "SourceCodePro-Bold",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Bold.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Semibold",
            full_name: "Source Code Pro Semibold",
            post_script_name: "SourceCodePro-Semibold",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Semibold.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Light Italic",
            full_name: "Source Code Pro Light Italic",
            post_script_name: "SourceCodePro-LightIt",
            version: "1.050;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-LightIt.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Medium",
            full_name: "Source Code Pro Medium",
            post_script_name: "SourceCodePro-Medium",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Medium.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Code Pro",
            style: "Light",
            full_name: "Source Code Pro Light",
            post_script_name: "SourceCodePro-Light",
            version: "2.030;PS 1.000;hotconv 16.6.51;makeotf.lib2.5.65220",
            filename: "SourceCodePro-Light.ttf",
            copyright: "Copyright 2010, 2012 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
        ]
      )

      provides_font(
        "Source Sans Pro",
        match_styles_from_file: [
          {
            family_name: "Source Sans Pro",
            style: "Black Italic",
            full_name: "Source Sans Pro Black Italic",
            post_script_name: "SourceSansPro-BlackIt",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-BlackIt.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Italic",
            full_name: "Source Sans Pro Italic",
            post_script_name: "SourceSansPro-It",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-It.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Light",
            full_name: "Source Sans Pro Light",
            post_script_name: "SourceSansPro-Light",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-Light.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "ExtraLight",
            full_name: "Source Sans Pro ExtraLight",
            post_script_name: "SourceSansPro-ExtraLight",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-ExtraLight.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "ExtraLight Italic",
            full_name: "Source Sans Pro ExtraLight Italic",
            post_script_name: "SourceSansPro-ExtraLightIt",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-ExtraLightIt.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Bold Italic",
            full_name: "Source Sans Pro Bold Italic",
            post_script_name: "SourceSansPro-BoldIt",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-BoldIt.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Black",
            full_name: "Source Sans Pro Black",
            post_script_name: "SourceSansPro-Black",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-Black.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Light Italic",
            full_name: "Source Sans Pro Light Italic",
            post_script_name: "SourceSansPro-LightIt",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-LightIt.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Regular",
            full_name: "Source Sans Pro",
            post_script_name: "SourceSansPro-Regular",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-Regular.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Semibold",
            full_name: "Source Sans Pro Semibold",
            post_script_name: "SourceSansPro-Semibold",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-Semibold.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Bold",
            full_name: "Source Sans Pro Bold",
            post_script_name: "SourceSansPro-Bold",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-Bold.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Sans Pro",
            style: "Semibold Italic",
            full_name: "Source Sans Pro Semibold Italic",
            post_script_name: "SourceSansPro-SemiboldIt",
            version: "3.006;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSansPro-SemiboldIt.ttf",
            copyright: "© 2010 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
        ]
      )

      provides_font(
        "Source Serif Pro",
        match_styles_from_file: [
          {
            family_name: "Source Serif Pro",
            style: "Black",
            full_name: "Source Serif Pro Black",
            post_script_name: "SourceSerifPro-Black",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-Black.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Bold",
            full_name: "Source Serif Pro Bold",
            post_script_name: "SourceSerifPro-Bold",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-Bold.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Bold Italic",
            full_name: "Source Serif Pro Bold Italic",
            post_script_name: "SourceSerifPro-BoldIt",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-BoldIt.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Regular",
            full_name: "Source Serif Pro",
            post_script_name: "SourceSerifPro-Regular",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-Regular.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "ExtraLight",
            full_name: "Source Serif Pro ExtraLight",
            post_script_name: "SourceSerifPro-ExtraLight",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-ExtraLight.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Semibold Italic",
            full_name: "Source Serif Pro Semibold Italic",
            post_script_name: "SourceSerifPro-SemiboldIt",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-SemiboldIt.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Black Italic",
            full_name: "Source Serif Pro Black Italic",
            post_script_name: "SourceSerifPro-BlackIt",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-BlackIt.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Semibold",
            full_name: "Source Serif Pro Semibold",
            post_script_name: "SourceSerifPro-Semibold",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-Semibold.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Light",
            full_name: "Source Serif Pro Light",
            post_script_name: "SourceSerifPro-Light",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-Light.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Light Italic",
            full_name: "Source Serif Pro Light Italic",
            post_script_name: "SourceSerifPro-LightIt",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-LightIt.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "ExtraLight Italic",
            full_name: "Source Serif Pro ExtraLight Italic",
            post_script_name: "SourceSerifPro-ExtraLightIt",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-ExtraLightIt.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
          {
            family_name: "Source Serif Pro",
            style: "Italic",
            full_name: "Source Serif Pro Italic",
            post_script_name: "SourceSerifPro-It",
            version: "3.001;hotconv 1.0.111;makeotfexe 2.5.65597",
            filename: "SourceSerifPro-It.ttf",
            copyright: "© 2014 - 2019 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name ‘Source’.",
          },
        ]
      )

      %w(ExtraLight Light Normal Regular Bold Heavy).each do |style|
        provides_font_collection do |coll|
          filename "SourceHanSans-#{style}.ttc"

          ["", " TC", " K", " HC", " SC"].each do |variant|
            provides_font "Source Hans Sans#{variant}", extract_styles_from_collection: {
              style.to_s => {
                name: "Source Hans Sans#{variant}",
                style: style
              }
            }
          end
        end
      end

      def extract
        resource("source-fonts.zip") do |resource|
          zip_extract(resource, fonts_sub_dir: "fonts/") do |fontdir|
            match_fonts(fontdir, "Source Code Pro")
            match_fonts(fontdir, "Source Sans Pro")
            match_fonts(fontdir, "Source Serif Pro")
            match_fonts(fontdir, "Source Han Sans")
          end
        end
      end

      def install
        case platform
        when :macos
          install_matched_fonts "$HOME/Library/Fonts/Microsoft"
        when :linux
          install_matched_fonts "/usr/share/fonts/truetype/microsoft"
        end
      end

      test do
        case platform
        when :macos
          assert_predicate "$HOME/Library/Fonts/Microsoft/tahoma.ttf", :exist?
        when :linux
          assert_predicate "/usr/share/fonts/truetype/microsoft/tahoma.ttf", :exist?
        end
      end

    end
  end
end
