require "spec_helper"

RSpec.describe Fontist::SystemFont do
  describe ".find" do
    context "with a vlaid existing font" do
      it "returns the complete font path" do
        name = "DejaVuSerif.ttf"
        dejavu_ttf = Fontist::SystemFont.find(name, sources: [font_sources])

        expect(dejavu_ttf).not_to be_nil
        expect(dejavu_ttf.first).to include("spec/fixtures/fonts/")
      end
    end

    context "with invalid font" do
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
