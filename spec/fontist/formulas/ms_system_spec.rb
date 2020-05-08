require "spec_helper"

RSpec.describe Fontist::Formulas::MsSystem do
  describe ".fetch_font" do
    context "with valid licence", file_download: true do
      it "downloads and returns font paths" do
        name = "Times"
        stub_fontist_path_to_assets

        fonts = Fontist::Formulas::MsSystem.fetch_font(
          name, confirmation: "yes"
        )

        expect(fonts).not_to be_empty
        expect(fonts.first).to include(name)
        expect(Fontist::Finder.find(name)).not_to be_empty
      end
    end

    context "with invalid licence agreement" do
      it "raise an licensing error" do
        font_name = "Times"
        stub_fontist_path_to_assets

        expect {
          Fontist::Formulas::MsSystem.fetch_font(font_name, confirmation: "no")
        }.to raise_error(Fontist::Errors::LicensingError)
      end
    end
  end
end
