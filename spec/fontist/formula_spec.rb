require "spec_helper"

RSpec.describe Fontist::Formula do
  describe ".find" do
    context "by font name" do
      it "returns the font formulas" do
        name = "Calibri"

        clear_type = Fontist::Formula.find(name)

        expect(clear_type.fonts.map(&:name)).to include(name)
        expect(clear_type.installer).to eq("Fontist::Formulas::ClearTypeFonts")
        expect(clear_type.description).to include("Microsoft ClearType Fonts")
      end
    end

    context "by exact font" do
      it "returns the font formulas" do
        name = "CAMBRIAI.TTF"

        clear_type = Fontist::Formula.find(name)
        font_files = clear_type.fonts.map { |font| font.styles.map(&:font) }

        expect(font_files.flatten).to include(name)
        expect(clear_type.installer).to eq("Fontist::Formulas::ClearTypeFonts")
        expect(clear_type.description).to include("Microsoft ClearType Fonts")
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
      font = Fontist::Formula.find_fonts(name).last

      expect(font.styles.map(&:font)).to include("CALIBRI.TTF")
      expect(font.styles.map(&:font)).to include("CALIBRIB.TTF")
      expect(font.styles.map(&:font)).to include("CALIBRII.TTF")
    end

    it "returns nil if invalid name provided" do
      name = "Calibri Invlaid"
      fonts = Fontist::Formula.find_fonts(name)

      expect(fonts).to be_nil
    end
  end

  describe ".all" do
    it "returns all registered formulas" do
      formulas = Fontist::Formula.all

      expect(formulas.cleartype.fonts.count).to be > 10
      expect(formulas.cleartype.homepage).to eq("https://www.microsoft.com")
      expect(formulas.cleartype.description).to eq("Microsoft ClearType Fonts")
    end
  end
end
