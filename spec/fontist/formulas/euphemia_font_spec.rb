require "spec_helper"

RSpec.describe Fontist::Formulas::EuphemiaFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::EuphemiaFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("Euphemia UCAS")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts" do
        name = "Euphemia UCAS"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::EuphemiaFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name} Italic 2.6.6.ttf")
      end
    end
  end
end
