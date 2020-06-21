require "spec_helper"

RSpec.describe Fontist::Formulas::CourierFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::CourierFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("Courier")
    end
  end

  describe "installation" do
    context "with valid licence agreement", slow: true do
      it "installs the valid fonts", skip_in_windows: true do
        name = "Courier"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::CourierFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/cour.ttf")
      end
    end
  end
end
