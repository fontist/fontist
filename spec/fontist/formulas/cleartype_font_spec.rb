require "spec_helper"

RSpec.describe Fontist::Formulas::ClearTypeFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = described_class.instance

      expect(formula.fonts.count).to eq(12)
      expect(formula.fonts[1][:name]).to eq("Cambria Math")
      expect(formula.fonts.first[:name]).to eq("Cambria")
    end
  end

  describe "installation" do
    context "with valid licence agreement", slow: true do
      it "installs the valid fonts", unless: Gem.win_platform? do
        name = "Cambria"
        confirmation = "yes"

        paths = described_class.fetch_font(
          name, confirmation: confirmation
        )

        expect(paths).to include(include("fonts/#{name.upcase}.TTC"))
      end
    end

    context "with missing licence agreement" do
      it "raises an Fontist::Errors::LicensingError" do
        name = "Calibri"

        expect { described_class.fetch_font(name, confirmation: "no") }
          .to raise_error(Fontist::Errors::LicensingError)
      end
    end
  end
end
