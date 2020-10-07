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
          status = described_class.start(["status", "source hans sans"])
          expect(status).to be 0
        end
      end
    end
  end
end
