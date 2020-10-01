require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  describe "#install" do
    it "installs font by name" do
      stub_fonts_path_to_new_path do
        described_class.start(["install", "overpass"])
        expect(font_file("overpass-regular.otf")).to exist
        expect(font_file("overpass-mono-regular.otf")).not_to exist
      end
    end

    context "font and style" do
      context "zip archive" do
        it "installs only one style of a font" do
          stub_fonts_path_to_new_path do
            described_class.start(["install", "overpass", "bold"])
            expect(font_file("overpass-bold.otf")).to exist
            expect(font_file("overpass-regular.otf")).not_to exist
          end
        end
      end

      context "cab archive" do
        it "installs only one style of a font" do
          stub_system_fonts
          stub_license_agreement_prompt_with("yes")
          stub_fonts_path_to_new_path do
            described_class.start(["install", "cambria", "bold"])
            expect(font_file("CAMBRIAB.TTF")).to exist
            expect(font_file("CAMBRIAI.TTF")).not_to exist
          end
        end
      end

      context "second style" do
        it "installs the second style" do
          stub_fonts_path_to_new_path do
            described_class.start(["install", "overpass", "bold"])
            expect(font_file("overpass-regular.otf")).not_to exist
            described_class.start(["install", "overpass", "italic"])
            expect(font_file("overpass-italic.otf")).to exist
          end
        end
      end

      context "no such style" do
        it "returns error status" do
          stub_system_fonts
          stub_license_agreement_prompt_with("yes")
          stub_fonts_path_to_new_path do
            status = described_class.start(["install", "comic", "italic"])
            expect(status).to be 1
            expect(Dir.empty?(Fontist.fonts_path)).to be true
          end
        end
      end
    end

    context "several fonts in formula" do
      it "installs all fonts" do
        stub_system_fonts
        stub_license_agreement_prompt_with("yes")
        stub_fonts_path_to_new_path do
          result = described_class.start(["install", "cleartype"])
          expect(result).to be 0
          expect(font_file("CALIBRI.TTF")).to exist
          expect(font_file("CANDARA.TTF")).to exist
        end
      end
    end
  end
end
