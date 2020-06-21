require "spec_helper"

RSpec.describe Fontist::Formulas::MontserratFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::MontserratFont.instance

      expect(formula.fonts.count).to eq(2)
      expect(formula.fonts.first[:name]).to eq("Montserrat")
    end
  end

  describe "installation" do
    context "with valid licence agreement", slow: true do
      it "installs the valid fonts" do
        name = "Montserrat"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::MontserratFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name}-Thin.otf")
      end
    end
  end
end
