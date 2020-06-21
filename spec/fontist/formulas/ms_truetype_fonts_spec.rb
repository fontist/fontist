require "spec_helper"

RSpec.describe Fontist::Formulas::MsTruetypeFonts do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::MsTruetypeFonts.instance

      expect(formula.fonts.count).to eq(4)
      expect(formula.fonts.first[:name]).to eq("Arial")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts", skip_in_windows: true do
        name = "Arial"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::MsTruetypeFonts.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name}.ttf")
      end
    end
  end
end
