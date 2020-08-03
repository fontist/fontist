require "spec_helper"

RSpec.describe Fontist::SystemFont do
  describe ".find" do
    context "with a valid existing font" do
      it "returns the complete font path" do
        name = "DejaVuSerif.ttf"
        dejavu_ttf = Fontist::SystemFont.find(name, sources: [font_sources])

        expect(dejavu_ttf).not_to be_nil
        expect(dejavu_ttf.first).to include("spec/fixtures/fonts/")
      end
    end

    context "with valid font name" do
      it "returns the complete font path", slow: true do
        name = "Calibri"
        stub_fontist_path_to_temp_path
        Fontist::Formulas::ClearTypeFonts.fetch_font(name, confirmation: "yes")

        calbiri = Fontist::SystemFont.find(name, sources: [font_sources])
        expect(calbiri.join("|").downcase).to include("#{name.downcase}.ttf")
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
  end

  def font_sources
    @font_sources ||= Fontist.root_path.join("spec/fixtures/fonts/*")
  end
end
