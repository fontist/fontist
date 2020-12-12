require "spec_helper"

RSpec.describe Fontist::Formulas::ImpactFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::ImpactFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("Impact")
    end
  end

  describe "installation" do
    context "with valid licence agreement", slow: true do
      it "installs the valid fonts", unless: Gem.win_platform? do
        name = "Impact"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::ImpactFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name}.TTF")
      end
    end
  end
end
