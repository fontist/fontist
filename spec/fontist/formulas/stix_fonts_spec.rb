require "spec_helper"

RSpec.describe Fontist::Formulas::StixFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::StixFont.instance

      expect(formula.fonts.count).to eq(2)
      expect(formula.fonts.first[:name]).to eq("STIX Two Math")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts" do
        name = "STIX Two Math"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::StixFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths).to include(include("fonts/STIX2Math.otf"))
      end
    end
  end
end
