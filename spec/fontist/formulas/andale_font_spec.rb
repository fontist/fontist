require "spec_helper"

RSpec.describe Fontist::Formulas::AndaleFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::AndaleFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("Andale Mono")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts", skip_in_windows: true do
        name = "Andale Mono"
        confirmation = "yes"

        stub_fontist_path_to_assets
        paths = Fontist::Formulas::AndaleFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Finder.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/AndaleMo.TTF")
      end
    end
  end
end
