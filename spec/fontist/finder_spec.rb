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
      it "downloads the fonts and copy to path" do
        name = "CALIBRI.TTF"
        fake_font_path = "./assets/fonts/#{name}"
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        allow(Fontist::MsVistaFont).to(
          receive(:fetch_font). and_return(fake_font_path)
        )

        calibri_ttf = Fontist::Finder.find(name)

        expect(calibri_ttf).to include(fake_font_path)
        expect(Fontist::MsVistaFont).to have_received(:fetch_font).with(name)
      end
    end

    context "with invalid font name" do
      it "raise an missing font error" do
        font_name = "InvalidFont.ttf"

        expect {
          Fontist::Finder.find(font_name)
        }.to raise_error(Fontist::Error, "Could not find the #{font_name} font")
      end
    end
  end
end
