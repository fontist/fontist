require "spec_helper"

RSpec.describe Fontist::SystemFont do
  describe ".find" do
    context "with a valid existing font" do
      it "returns the complete font path" do
        stub_system_fonts

        name = "DejaVu Serif"
        dejavu_ttf = Fontist::SystemFont.find(name, sources: [font_sources])

        expect(dejavu_ttf).not_to be_nil
        expect(dejavu_ttf.first).to include("spec/fixtures/fonts/")
      end
    end

    context "with valid font name" do
      it "returns the complete font path", slow: true do
        no_fonts do
          example_font_to_fontist("CAMBRIA.TTC")

          paths = Fontist::SystemFont.find("Cambria")
          expect(paths).to include(include("CAMBRIA.TTC"))
        end
      end
    end

    context "with invalid font" do
      it "returns nil for partial-not match" do
        name = "Deje"
        expect(Fontist::SystemFont.find(name)).to be_nil
      end

      it "returns nill to the caller" do
        name = "invalid-font.ttf"
        invalid_font = Fontist::SystemFont.find(name, sources: [font_sources])

        expect(invalid_font).to be_nil
      end
    end

    context "filename not include full style" do
      it "returns only requested style" do
        no_fonts do
          example_font_to_system("ariali.ttf")
          example_font_to_system("arialbi.ttf")

          result = Fontist::SystemFont.find_with_name("Arial", "Italic")
          expect(result[:paths]).to match [include("ariali.ttf")]
          expect(result[:paths]).not_to include(include("arialbi.ttf"))
        end
      end
    end

    context "collection fonts" do
      it "could return all collection fonts" do
        no_fonts do
          example_font_to_system("Times.ttc")

          ["Regular", "Italic", "Bold", "Bold Italic"].each do |style|
            result = Fontist::SystemFont.find_with_name("Times", style)
            expect(result[:paths]).to match [include("Times.ttc")]
          end
        end
      end
    end
  end

  def font_sources
    @font_sources ||= Fontist.root_path.join("spec/fixtures/fonts/*")
  end
end
