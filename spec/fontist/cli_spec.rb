require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  describe "#install" do
    before { stub_system_fonts }

    context "supported font name" do
      it "returns success status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "overpass"])
          expect(status).to be 0
        end
      end
    end

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "unexisting"])
          expect(status).to be 1
        end
      end
    end
  end

  describe "#status" do
    before { stub_system_fonts }

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "unexisting"])
          expect(status).to be 1
        end
      end
    end

    context "supported font name but uninstalled" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "andale"])
          expect(status).to be 1
        end
      end
    end

    context "supported and installed font" do
      it "returns success status and prints path" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success).with(include("AndaleMo.TTF"))
          status = described_class.start(["status", "andale"])
          expect(status).to be 0
        end
      end

      it "shows formula and font names" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success)
            .with("Fontist::Formulas::AndaleFont")
          expect(Fontist.ui).to receive(:success)
            .with(" Andale Mono")
          expect(Fontist.ui).to receive(:success)
            .with(/^  Regular \(.*AndaleMo.TTF\)/)
          described_class.start(["status", "andale"])
        end
      end
    end

    context "no font specified" do
      it "returns success status and tells there is no installed font" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with("No font is installed.")
          status = described_class.start(["status"])
          expect(status).to be 1
        end
      end
    end

    context "collection font" do
      it "returns collection name" do
        stub_fonts_path_to_new_path do
          stub_font_file("SourceHanSans-ExtraLight.ttc")

          expect(Fontist.ui).to receive(:success)
            .with(include("ExtraLight"))
          status = described_class.start(["status", "source han sans"])
          expect(status).to be 0
        end
      end
    end
  end

  describe "#list" do
    before { stub_system_fonts }

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["list", "unexisting"])
          expect(status).to be 1
        end
      end
    end

    context "supported font name but uninstalled" do
      it "prints `uninstalled`" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with(include("uninstalled"))
          status = described_class.start(["list", "andale"])
          expect(status).to be 0
        end
      end
    end

    context "supported and installed font" do
      it "prints `installed`" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success).with(include("(installed)"))
          status = described_class.start(["list", "andale"])
          expect(status).to be 0
        end
      end

      it "shows formula and font names" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say)
            .with("Fontist::Formulas::AndaleFont")
          expect(Fontist.ui).to receive(:say)
            .with(" Andale Mono")
          expect(Fontist.ui).to receive(:success)
            .with(/^  Regular \(installed\)/)
          described_class.start(["list", "andale"])
        end
      end
    end

    context "no font specified" do
      it "returns success status and prints list with no installed status" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).at_least(1000).times
          expect(Fontist.ui).to receive(:success).exactly(0).times
          status = described_class.start(["list"])
          expect(status).to be 0
        end
      end
    end
  end

  describe "#locations" do
    let(:command) { described_class.start(["locations", path]) }
    let(:path) { Tempfile.new.tap { |f| f.write(content) && f.close }.path }
    let(:content) { YAML.dump(manifest) }
    let(:output) { include_yaml(result) }

    context "manifest not found" do
      let(:path) { Fontist.root_path.join("unexisting") }

      it "tells manifest could not be found" do
        expect(Fontist.ui).to receive(:error)
          .with("Manifest could not be found.")
        expect(command).to be 1
      end
    end

    context "empty manifest" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error)
          .with("Manifest could not be read.")
        expect(command).to be 1
      end
    end

    context "contains no font" do
      let(:manifest) { {} }
      let(:result) { {} }

      it "returns empty result" do
        expect(Fontist.ui).to receive(:say).with(output)
        expect(command).to be 0
      end
    end

    context "contains one font with regular style" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      let(:result) { { "Andale Mono" => { "Regular" => [andale_path] } } }
      let(:andale_path) { font_path("AndaleMo.TTF") }

      it "returns font location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end

    context "contains one font with bold style" do
      let(:manifest) { { "Courier" => "Bold" } }
      let(:result) { { "Courier" => { "Bold" => [courier_path] } } }
      let(:courier_path) { font_path("courbd.ttf") }

      it "returns font location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("courbd.ttf")

          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end

    context "contains two fonts" do
      let(:manifest) do
        { "Andale Mono" => "Regular",
          "Courier" => "Bold" }
      end

      let(:result) do
        { "Andale Mono" => { "Regular" => [font_path("AndaleMo.TTF")] },
          "Courier" => { "Bold" => [font_path("courbd.ttf")] } }
      end

      it "returns font location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")
          stub_font_file("courbd.ttf")

          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end

    context "contains one font from system paths" do
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "returns font location" do
        stub_system_fonts_path_to_new_path do |system_dir|
          stub_font_file("Andale Mono.ttf", system_dir)

          stub_fonts_path_to_new_path do
            expect(Fontist.ui).to receive(:say).with(include(system_dir))
            expect(command).to be 0
          end
        end
      end
    end

    context "contains font with space from system paths" do
      let(:manifest) { { "Noto Sans" => "Regular" } }
      let(:result) do
        { "Noto Sans" => { "Regular" => [include("NotoSansOriya.ttc")] } }
      end

      it "returns no-space location" do
        stub_system_fonts_path_to_new_path do |system_dir|
          stub_font_file("NotoSansOriya.ttc", system_dir)

          stub_fonts_path_to_new_path do
            expect(Fontist.ui).to receive(:say).with(include_yaml(result))
            expect(command).to be 0
          end
        end
      end
    end

    context "contains uninstalled font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      let(:result) { { "Andale Mono" => { "Regular" => [] } } }

      it "returns no location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end

    context "contains unsupported font" do
      let(:manifest) { { "Unsupported Font" => "Regular" } }
      let(:result) { { "Unsupported Font" => { "Regular" => [] } } }

      it "returns no location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end
  end
end
