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
      it "installs and returns paths for fonts with open license" do
        stub_fontist_path_to_temp_path

        font = { name: "Overpass Mono", filename: "overpass-mono-regular.otf" }
        font_paths = Fontist::Font.install(font[:name], confirmation: "no")

        expect(font_paths.join("|").downcase).to include(font[:filename])
      end

      it "install proprietary fonts with correct license agreement" do
        stub_fontist_path_to_temp_path
        stub_license_agreement_prompt_with("yes")

        font = { name: "Calibri", filename: "calibri.ttf" }
        font_paths = Fontist::Font.install(font[:name])

        expect(font_paths.join("|").downcase).to include(font[:filename])
      end

      it "raises error for missing license agreement" do
        stub_fontist_path_to_temp_path
        stub_license_agreement_prompt_with("no")

        font = { name: "Calibri", filename: "calibri.ttf" }
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        expect { Fontist::Font.install(font[:name]) }.to raise_error(
          Fontist::Errors::LicensingError
        )
      end
    end

    context "with valid formula name" do
      it "installs all fonts and returns theirs paths" do
        stub_system_fonts
        stub_license_agreement_prompt_with("yes")
        stub_fonts_path_to_new_path do
          font = { name: "cleartype", filename: "CALIBRI.TTF" }
          font_paths = Fontist::Font.install(font[:name])

          expect(font_file(font[:filename])).to exist
          expect(font_paths.join("|")).to include(font[:filename])
        end
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

    context "with msi archive" do
      it "installs and returns paths for fonts" do
        stub_fontist_path_to_temp_path

        font = { name: "Adobe Arabic", filename: "adobearabic_bold.otf" }
        font_paths = Fontist::Font.install(font[:name], confirmation: "no")

        expect(font_paths.join("|").downcase).to include(font[:filename])
      end
    end

    context "with 7z archive" do
      it "installs and returns paths for fonts" do
        stub_fontist_path_to_temp_path

        font = { name: "Adobe Pi Std", filename: "adobepistd.otf" }
        font_paths = Fontist::Font.install(font[:name], confirmation: "no")

        expect(font_paths.join("|").downcase).to include(font[:filename])
      end
    end
  end
end
