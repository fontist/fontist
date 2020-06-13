require "spec_helper"

RSpec.describe Fontist::Font do
  describe ".find" do
    context "with valid font name" do
      it "returns the fonts path" do
        name = "DejaVuSerif.ttf"
        stub_system_font_finder_to_fixture(name)
        dejavu_ttf = Fontist::Font.find(name)

        expect(dejavu_ttf.first).to include(name)
      end
    end

    context "with downloadable font name" do
      it "raises font missing error" do
        name = "Courier"
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        expect {
          Fontist::Font.find(name)
        }.to raise_error(Fontist::Errors::MissingFontError)
      end
    end

    context "with invalid font name" do
      it "raises font unsupported error" do
        font_name = "InvalidFont.ttf"

        expect {
          Fontist::Font.find(font_name)
        }.to raise_error(Fontist::Errors::NonSupportedFontError)
      end
    end
  end

  def stub_system_font_finder_to_fixture(name)
    allow(Fontist::SystemFont).to receive(:find).
      and_return(["spec/fixtures/fonts/#{name}"])
  end
end
