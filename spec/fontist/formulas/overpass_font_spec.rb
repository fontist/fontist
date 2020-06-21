require "spec_helper"

RSpec.describe Fontist::Formulas::OverpassFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::OverpassFont.instance

      expect(formula.fonts.count).to eq(2)
      expect(formula.fonts.first[:name]).to eq("Overpass")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts" do
        name = "Overpass"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::OverpassFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name.downcase}-bold-italic.otf")
      end
    end
  end
end
