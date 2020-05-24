require "spec_helper"

RSpec.describe Fontist::Formulas::CourierFont do
  describe ".fetch_font" do
    context "with valid licence", skip_in_windows: true do
      it "downloads and returns the fonts", skip: true do
        name = "Courier"
        stub_fontist_path_to_assets
        fonts = Fontist::Formulas::CourierFont.fetch_font(
          name, confirmation: "yes", force_download: true
        )

        expect(fonts.count).to eq(4)
        expect(fonts.first).to include("fonts/cour.ttf")
        expect(Fontist::Finder.find(name)).not_to be_empty
      end
    end

    context "with invalid licence agreement" do
      it "raise an licensing error" do
        font_name = "cour"
        stub_fontist_path_to_assets

        expect {
          Fontist::Formulas::CourierFont.fetch_font(font_name, confirmation: "no")
        }.to raise_error(Fontist::Errors::LicensingError)
      end
    end
  end
end
