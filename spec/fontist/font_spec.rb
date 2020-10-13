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

  describe ".uninstall" do
    let(:command) { Fontist::Font.uninstall(font) }

    context "with unsupported font" do
      let(:font) { "unexisting" }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::NonSupportedFontError
      end
    end

    context "with unsupported font but available in system" do
      let(:font) { "menlo" }
      before { stub_system_font_to("/System/Library/Fonts/Menlo.ttc") }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::NonSupportedFontError
      end
    end

    context "with supported font but not installed" do
      let(:font) { "overpass" }

      it "raises font missing error" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect { command }.to raise_error Fontist::Errors::MissingFontError
        end
      end
    end

    context "with supported and installed font" do
      it "removes font" do
        stub_fonts_path_to_new_path do
          stub_font_file("overpass-regular.otf")

          Fontist::Font.uninstall("overpass")
          expect(font_file("overpass-regular.otf")).not_to exist
        end
      end
    end

    context "with supported but half of name specified" do
      let(:font) { "segoe" }

      it "keeps other fonts" do
        stub_fonts_path_to_new_path do
          stub_font_file("overpass-regular.otf")

          expect { command }.to raise_error Fontist::Errors::MissingFontError
          expect(font_file("overpass-regular.otf")).to exist
        end
      end
    end
  end

  describe ".status" do
    let(:command) { Fontist::Font.status(font) }

    context "with unsupported font" do
      let(:font) { "unexisting" }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::NonSupportedFontError
      end
    end

    context "with supported font but not installed" do
      let(:font) { "andale" }

      it "raises font missing error" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect { command }.to raise_error Fontist::Errors::MissingFontError
        end
      end
    end

    context "with supported and installed font" do
      let(:font) { "andale" }

      it "returns its path" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(command.size).to be 1

          formula, fonts = command.first
          expect(formula.installer).to eq "Fontist::Formulas::AndaleFont"

          font, styles = fonts.first
          expect(font.name).to eq "Andale Mono"

          _style, path = styles.first
          expect(path).to include("AndaleMo.TTF")
        end
      end
    end

    context "with no font and nothing installed" do
      let(:font) { nil }

      it "returns no font" do
        stub_fonts_path_to_new_path do
          expect(command.size).to be 0
        end
      end
    end

    context "with no font and a font installed" do
      let(:font) { nil }

      it "returns installed font with its path" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(command.size).to be 1

          formula, fonts = command.first
          expect(formula.installer).to eq "Fontist::Formulas::AndaleFont"

          font, styles = fonts.first
          expect(font.name).to eq "Andale Mono"

          _style, path = styles.first
          expect(path).to include("AndaleMo.TTF")
        end
      end
    end
  end

  describe ".list" do
    let(:command) { Fontist::Font.list(font) }

    context "with unsupported font" do
      let(:font) { "unexisting" }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::NonSupportedFontError
      end
    end

    context "with supported font but not installed" do
      let(:font) { "andale" }

      it "returns its status as uninstalled" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(command.size).to be 1

          _, _, _, installed = unpack_status(command)
          expect(installed).to be false
        end
      end
    end

    context "with supported and installed font" do
      let(:font) { "andale" }

      it "returns its status as installed" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(command.size).to be 1
          _, _, _, installed = unpack_status(command)
          expect(installed).to be true
        end
      end
    end

    context "with no font and nothing installed" do
      let(:font) { nil }

      it "returns all fonts" do
        stub_fonts_path_to_new_path do
          expect(command.size).to be > 1000
          _, _, _, installed = unpack_status(command)
          expect(installed).to be false
        end
      end
    end

    context "with no font and a font installed" do
      let(:font) { nil }

      it "returns installed font with its path" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("andalemo.ttf")

          expect(command.size).to be > 1000

          statuses = command.map do |_, fonts|
            fonts.map do |_, styles|
              styles.values
            end
          end.flatten

          expect(statuses).to include(true)
        end
      end
    end
  end

  def unpack_status(formulas)
    formula, fonts = formulas.first
    font, styles = fonts.first
    style, status = styles.first
    [formula, font, style, status]
  end
end
