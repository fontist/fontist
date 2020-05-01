require "spec_helper"

RSpec.describe Fontist::MsVistaFont do
  describe ".fetch_font" do
    context "with valid licence", api_call: true do
      it "downloads and returns font paths" do
        name = "CANDARAI.TTF"
        fonts = Fontist::MsVistaFont.fetch_font(
          name, confirmation: "yes", force_download: true
        )

        expect(fonts.count).to eq(1)
        expect(fonts.first).to include("CANDARAI.TTF")
      end
    end

    context "with invalid licence agreement" do
      it "raise an licensing error" do
        font_name = "CANDARAI.TTF"

        expect {
          Fontist::MsVistaFont.fetch_font(font_name, confirmation: "no")
        }.to raise_error(Fontist::Errors::LicensingError)
      end
    end
  end
end
