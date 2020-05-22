require "spec_helper"

RSpec.describe Fontist::FormulaFinder do
  describe ".find" do
    context "by font name" do
      it "returns the font formulas" do
        name = "Calibri"
        formulas = Fontist::FormulaFinder.find(name)

        expect(formulas.count).to eq(1)
        expect(formulas.first[:key]).to eq("msvista")
        expect(formulas.first[:installer]).to eq(Fontist::Formulas::MsVista)
      end
    end

    context "by exact font" do
      it "returns the font formulas" do
        name = "CAMBRIAI.TTF"
        formulas = Fontist::FormulaFinder.find(name)

        expect(formulas.count).to eq(1)
        expect(formulas.first[:key]).to eq("msvista")
        expect(formulas.first[:installer]).to eq(Fontist::Formulas::MsVista)
      end
    end

    context "for invalid font" do
      it "returns nil to the caller" do
        name = "Calibri Made Up Name"
        formulas = Fontist::FormulaFinder.find(name)

        expect(formulas).to be_nil
      end
    end
  end

  describe ".find_fonts" do
    it "returns the exact font font names" do
      name = "Calibri"
      font = Fontist::FormulaFinder.find_fonts(name).first

      expect(font.styles.map(&:font)).to include("CALIBRI.TTF")
      expect(font.styles.map(&:font)).to include("CALIBRIB.TTF")
      expect(font.styles.map(&:font)).to include("CALIBRII.TTF")
    end

    it "returns nil if invalid name provided" do
      name = "Calibri Invlaid"
      fonts = Fontist::FormulaFinder.find_fonts(name)

      expect(fonts).to be_nil
    end
  end
end
