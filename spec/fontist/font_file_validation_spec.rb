require "spec_helper"

RSpec.describe Fontist::FontFile do
  describe ".from_path" do
    context "with font that has validation issues" do
      # Rupali font has known issues with the 'name' table.
      # It's used to test that we can still extract metadata from
      # fonts with validation problems (lenient validation).
      let(:rupali_font_path) do
        Fontist.root_path.join("spec", "fixtures", "fonts", "corrupt",
                               "Rupali_0.72.ttf")
      end

      it "accepts font with validation issues (lenient validation)" do
        # The font has validation issues but we should still be able to load it
        font_file = described_class.from_path(rupali_font_path.to_s)
        expect(font_file).to be_a(Fontist::FontFile)
        expect(font_file.family).not_to be_nil
        expect(font_file.full_name).not_to be_nil
      end
    end

    context "with valid font" do
      let(:fixture_path) do
        Fontist.root_path.join("spec", "fixtures", "fonts", "DejaVuSerif.ttf")
      end

      it "accepts valid font" do
        font_file = described_class.from_path(fixture_path.to_s)
        expect(font_file).to be_a(Fontist::FontFile)
        expect(font_file.family).not_to be_nil
        expect(font_file.full_name).not_to be_nil
      end
    end
  end
end
