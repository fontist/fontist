require "spec_helper"

RSpec.describe Fontist::Formulas::ClearTypeFonts do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::ClearTypeFonts.instance

      expect(formula.fonts.count).to eq(12)
      expect(formula.fonts[1][:name]).to eq("Cambria Math")
      expect(formula.fonts.first[:name]).to eq("Cambria")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts", skip_in_windows: true do
        name = "Calibri"
        confirmation = "yes"

        paths = Fontist::Formulas::ClearTypeFonts.fetch_font(
          name, confirmation: confirmation
        )

        expect(paths.first).to include("fonts/#{name.upcase}.TTF")
      end
    end

    context "with missing licence agreement" do
      it "raises an Fontist::Errors::LicensingError" do
        name = "Calibri"

        expect {
          Fontist::Formulas::ClearTypeFonts.fetch_font(name, confirmation: "no")
        }.to raise_error(Fontist::Errors::LicensingError)
      end
    end
  end
end
