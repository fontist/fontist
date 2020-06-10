require "spec_helper"

RSpec.describe Fontist::Formulas::ComicFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::ComicFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("Comic Sans")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts", skip_in_windows: true do
        name = "Comic Sans"
        confirmation = "yes"

        stub_fontist_path_to_assets
        paths = Fontist::Formulas::ComicFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Finder.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/Comicbd.TTF")
      end
    end
  end
end
