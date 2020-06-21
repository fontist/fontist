require "spec_helper"

RSpec.describe Fontist::Font do
  describe ".all" do
    it "list all supported fonts" do
      fonts = Fontist::Font.all

      expect(fonts.count).to be > 10
      expect(fonts.first.name).not_to be_nil
      expect(fonts.first.styles).not_to be_nil
    end
  end

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

  describe ".install" do
    context "with valid font name" do
      it "installs the font and return the paths" do
        name = "Calibri"

        stub_fontist_path_to_temp_path
        font_paths = Fontist::Font.install(name, confirmation: "yes")

        expect(font_paths.join("|").downcase).to include("#{name.downcase}.ttf")
      end
    end

    context "with existing font name" do
      it "returns the existing font paths" do
        name = "Courier"
        stub_fontist_path_to_temp_path
        Fontist::Font.install(name, confirmation: "yes")

        font_paths = Fontist::Font.install(name, confirmation: "yes")

        expect(font_paths.count).to be > 3
        expect(Fontist::Formulas::CourierFont).not_to receive(:fetch_font)
      end
    end

    context "with unsupported fonts" do
      it "raises an unsupported error" do
        name = "Invalid font name"

        expect {
          Fontist::Font.install(name, confirmation: "yes")
        }.to raise_error(Fontist::Errors::NonSupportedFontError)
      end
    end
  end

  def stub_system_font_finder_to_fixture(name)
    allow(Fontist::SystemFont).to receive(:find).
      and_return(["spec/fixtures/fonts/#{name}"])
  end
end
