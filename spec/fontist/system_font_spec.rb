require "spec_helper"

RSpec.describe Fontist::SystemFont do
  describe ".find" do
    context "with a valid existing font" do
      it "returns the complete font path" do
        fresh_fonts_and_formulas do
          example_font("DejaVuSerif.ttf")

          paths = Fontist::SystemFont.find("DejaVu Serif")
          expect(paths.first).to include("DejaVuSerif.ttf")
        end
      end
    end

    context "with valid font name" do
      it "returns the complete font path" do
        no_fonts do
          example_font_to_fontist("CAMBRIA.TTC")

          paths = Fontist::SystemFont.find("Cambria")
          expect(paths).to include(include("CAMBRIA.TTC"))
        end
      end
    end

    context "with invalid font" do
      it "returns nil to the caller" do
        fresh_fonts_and_formulas do
          expect(Fontist::SystemFont.find("invalid-font.ttf")).to be_nil
        end
      end
    end

    context "filename not include full style" do
      it "returns only requested style" do
        no_fonts do
          example_font_to_system("ariali.ttf")
          example_font_to_system("arialbi.ttf")

          result = Fontist::SystemFont.find_styles("Arial", "Italic")
          paths = result.map(&:path)
          expect(paths).to match [include("ariali.ttf")]
          expect(paths).not_to include(include("arialbi.ttf"))
        end
      end
    end

    context "collection fonts" do
      it "could return all collection fonts" do
        no_fonts do
          example_font_to_system("Times.ttc")

          ["Regular", "Italic", "Bold", "Bold Italic"].each do |style|
            result = Fontist::SystemFont.find_styles("Times", style)
            paths = result.map(&:path)
            expect(paths).to match [include("Times.ttc")]
          end
        end
      end
    end

    context "system font has bad magic number" do
      include_context "fresh home"
      include_context "system fonts"

      before { example_font_to_system("NISC18030.ttf") }

      it "ignores this font, returns nil" do
        expect(Fontist::SystemFont.find("GB18030 Bitmap")).to be_nil
      end
    end
  end
end
