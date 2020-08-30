require "spec_helper"

RSpec.describe Fontist::Formulas::OpenSansFont do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::OpenSansFont.instance

      expect(formula.fonts.count).to eq(1)
      expect(formula.fonts.first[:name]).to eq("OpenSans")
    end
  end

  describe "installation" do
    context "with valid licence agreement", slow: true do
      it "installs the valid fonts" do
        name = "OpenSans"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::OpenSansFont.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths.first).to include("fonts/#{name}-Light.ttf")
      end
    end
  end
end
