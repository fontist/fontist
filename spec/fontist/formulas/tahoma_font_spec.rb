require "spec_helper"

RSpec.describe Fontist::Formulas::TahomaFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::TahomaFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("Tahoma")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts", skip_in_windows: true do
        name = "Tahoma"
        confirmation = "yes"

        stub_fontist_path_to_assets
        paths = Fontist::Formulas::TahomaFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Finder.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name.downcase}.ttf")
      end
    end
  end
end