require "spec_helper"

RSpec.describe Fontist::Formula do
  describe ".find" do
    context "by font name" do
      it "returns the font formulas" do
        clear_type = Fontist::Formula.find("Calibri")

        expect(clear_type.fonts.map(&:name)).to include("Calibri")
        expect(clear_type.key).to be
        expect(clear_type.description).to be
      end
    end

    context "for invalid font" do
      it "returns nil to the caller" do
        name = "Calibri Made Up Name"
        formulas = Fontist::Formula.find(name)

        expect(formulas).to be_nil
      end
    end
  end

  describe ".find_fonts" do
    it "returns the exact font font names" do
      name = "Calibri"
      fonts = Fontist::Formula.find_fonts(name)
      filenames = fonts.map(&:styles).flatten.map(&:font)

      expect(filenames).to include("CALIBRI.TTF")
      expect(filenames).to include("CALIBRIB.TTF")
      expect(filenames).to include("CALIBRII.TTF")
    end

    it "returns empty array if invalid name provided" do
      name = "Calibri Invlaid"
      fonts = Fontist::Formula.find_fonts(name)

      expect(fonts).to be_empty
    end
  end

  describe ".all" do
    it "returns all registered formulas" do
      formulas = Fontist::Formula.all

      expect(formulas.size).to be > 1000
      expect(formulas.first.fonts.size).to be > 0
      expect(formulas.first.description).to be_kind_of(String)
    end
  end

  describe "#from_hash" do
    let(:formula) { described_class.new_from_file(path) }
    let(:path) { Fontist.formulas_path.join("lato.yml").to_s }

    it "fills attributes" do
      expect(formula.key).to eq "lato"
      expect(formula.description).to be_kind_of(String)
      expect(formula.homepage).to be_kind_of(String)
      expect(formula.copyright).to be_kind_of(String)
      expect(formula.license_url).to be_kind_of(String)
      expect(formula.resources).to be_kind_of(Array)
      expect(formula.resources.first.urls.first).to be_kind_of(String)
      expect(formula.fonts).to be_kind_of(Array)
      expect(formula.fonts.first.name).to be_kind_of(String)
      expect(formula.fonts.first.styles).to be_kind_of(Array)
      expect(formula.fonts.first.styles.first.type).to be_kind_of(String)
      expect(formula.fonts.first.styles.first.font).to be_kind_of(String)
      expect(formula.extract.format).to be_kind_of(String)
      expect(formula.license).to be_kind_of(String)
      expect(formula.license_required).to be false
    end
  end
end
