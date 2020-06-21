require "spec_helper"

RSpec.describe Fontist::Formulas::SourceFonts do
  describe "initializing" do
    it "builds the data dictionary" do
      formula = Fontist::Formulas::SourceFonts.instance

      expect(formula.fonts.count).to eq(33)
      expect(formula.fonts.first[:name]).to eq("Source Code Pro")
    end
  end

  describe "installation" do
    context "with valid licence agreement" do
      it "installs the valid fonts" do
        name = "Source Code Pro"
        confirmation = "yes"

        stub_fontist_path_to_temp_path
        paths = Fontist::Formulas::SourceFonts.fetch_font(
          name, confirmation: confirmation
        )

        expect(Fontist::Font.find(name)).not_to be_empty
        expect(paths).to include(
          Fontist.fonts_path.join("SourceCodePro-Black.ttf").to_s
        )
      end
    end
  end
end
