require "spec_helper"

RSpec.describe Fontist::Finder do
  describe ".find" do
    context "with valid font name" do
      it "returns the fonts path" do
        name = "DejaVuSerif.ttf"
        dejavu_ttf = Fontist::Finder.find(name)

        expect(dejavu_ttf).to include(name)
      end
    end

    context "with downloadable ms vista font" do
      it "returns missing font error" do
        name = "CALIBRI.TTF"
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        expect {
          Fontist::Finder.find(name)
        }.to raise_error(Fontist::Errors::MissingFontError)
      end
    end

    context "with invalid font name" do
      it "raise an missing font error" do
        font_name = "InvalidFont.ttf"

        expect {
          Fontist::Finder.find(font_name)
        }.to raise_error(Fontist::Errors::NonSupportedFontError)
      end
    end
  end
end
