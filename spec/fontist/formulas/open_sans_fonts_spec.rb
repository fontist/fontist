require "spec_helper"

RSpec.describe Fontist::Formulas::OpenSansFonts do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::OpenSansFonts.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("OpenSans")
    end
  end

  describe "installation" do
    context "with valid licence agreement", file_download: true do
      it "installs the valid fonts", skip_in_windows: true do
        name = "OpenSans"
        confirmation = "yes"

        stub_fontist_path_to_assets
        paths = Fontist::Formulas::OpenSansFonts.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Finder.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name}-Light.ttf")
      end
    end
  end
end
