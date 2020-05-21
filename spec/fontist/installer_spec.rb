require "spec_helper"

RSpec.describe Fontist::Installer do
  describe ".download" do
    context "with already downloaded fonts", skip_in_windows: true do
      it "returns the font path", file_download: true do
        name = "Arial"
        Fontist::Formulas::MsVista.fetch_font(name, confirmation: "yes")

        allow(Fontist::Formulas::MsVista).to receive(:fetch_font).and_return(nil)
        paths = Fontist::Installer.download(name, confirmation: "yes")

        expect(paths.first).to include("fonts/#{name}")
      end
    end

    context "with missing but downloadable fonts" do
      it "downloads and install the fonts", skip_in_windows: true do
        name = "Arial"
        confirmation = "yes"
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        paths = Fontist::Installer.download(name, confirmation: confirmation)

        expect(paths.first).to include("fonts/#{name}")
      end

      it "do not download if user didn't agree" do
        name = "Calibri"
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        expect {
          Fontist::Installer.download(name, confirmation: "no")
        }.to raise_error(Fontist::Errors::LicensingError)
      end
    end

    context "with unsupported fonts" do
      it "raise an unsupported error" do
        name = "InvalidFont.ttf"

        expect {
          Fontist::Installer.download(name, confirmation: "yes")
        }.to raise_error(Fontist::Errors::NonSupportedFontError)
      end
    end
  end
end
