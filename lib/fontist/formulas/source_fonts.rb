module Fontist
  module Formulas
    class SourceFonts < FontFormula
      desc "Adobe Source Fonts"
      homepage "https://www.adobe.com"

      resource "source-fonts.zip" do
        url "https://github.com/fontist/source-fonts/releases/download/v1.0/source-fonts-1.0.zip"
        sha256 "0107b5d4ba305cb4dff2ba19138407aa2153632a2c41592f74d20cd0d0261bfd"
      end

      provides_font("Source Code Pro", match_styles_from_file: {
        "Black" => "SourceCodePro-Black.ttf",
        "Black Italic" => "SourceCodePro-BlackIt.ttf",
        "Bold" => "SourceCodePro-Bold.ttf",
        "Bold Italic" => "SourceCodePro-BoldIt.ttf",
        "Extra Light" => "SourceCodePro-ExtraLight.ttf",
        "ExtraLightIt" => "SourceCodePro-ExtraLightIt.ttf",
        "Italic" => "SourceCodePro-It.ttf",
        "Light" => "SourceCodePro-Light.ttf",
        "Light Italic" => "SourceCodePro-LightIt.ttf",
        "Medium" => "SourceCodePro-Medium.ttf",
        "Medium Italic" => "SourceCodePro-MediumIt.ttf",
        "Regular" => "SourceCodePro-Regular.ttf",
        "Semibold" => "SourceCodePro-Semibold.ttf",
        "Semibold Italic" => "SourceCodePro-SemiboldIt.ttf",
      })

      provides_font("Source Sans Pro", match_styles_from_file: {
        "Black" => "SourceSansPro-Black.ttf",
        "Black Italic" => "SourceSansPro-BlackIt.ttf",
        "Bold" => "SourceSansPro-Bold.ttf",
        "Bold Italic" => "SourceSansPro-BoldIt.ttf",
        "Extra Light" => "SourceSansPro-ExtraLight.ttf",
        "ExtraLightIt" => "SourceSansPro-ExtraLightIt.ttf",
        "Italic" => "SourceSansPro-It.ttf",
        "Light" => "SourceSansPro-Light.ttf",
        "Light Italic" => "SourceSansPro-LightIt.ttf",
        "Medium" => "SourceSansPro-Medium.ttf",
        "Medium Italic" => "SourceSansPro-MediumIt.ttf",
        "Regular" => "SourceSansPro-Regular.ttf",
        "Semibold" => "SourceSansPro-Semibold.ttf",
        "Semibold Italic" => "SourceSansPro-SemiboldIt.ttf",
      })

      provides_font("Source Serif Pro", match_styles_from_file: {
        "Black" => "SourceSerifPro-Black.ttf",
        "Black Italic" => "SourceSerifPro-BlackIt.ttf",
        "Bold" => "SourceSerifPro-Bold.ttf",
        "Bold Italic" => "SourceSerifPro-BoldIt.ttf",
        "Extra Light" => "SourceSerifPro-ExtraLight.ttf",
        "ExtraLightIt" => "SourceSerifPro-ExtraLightIt.ttf",
        "Italic" => "SourceSerifPro-It.ttf",
        "Light" => "SourceSerifPro-Light.ttf",
        "Light Italic" => "SourceSerifPro-LightIt.ttf",
        "Medium" => "SourceSerifPro-Medium.ttf",
        "Medium Italic" => "SourceSerifPro-MediumIt.ttf",
        "Regular" => "SourceSerifPro-Regular.ttf",
        "Semibold" => "SourceSerifPro-Semibold.ttf",
        "Semibold Italic" => "SourceSerifPro-SemiboldIt.ttf",
      })

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
