require "spec_helper"

RSpec.describe Fontist::FontFile do
  describe ".from_path" do
    context "with corrupt font" do
      let(:corrupt_font_path) do
        File.join(Dir.home,
                  "src/fontist/fontisan/spec/fixtures/fonts/Rupali/Rupali_0.72.ttf")
      end

      it "rejects corrupt font with validation error" do
        skip "Corrupt font fixture not available" unless File.exist?(corrupt_font_path)

        expect do
          described_class.from_path(corrupt_font_path)
        end.to raise_error(Fontist::Errors::FontFileError,
                           /indexability validation/)
      end

      it "includes validation details in error message" do
        skip "Corrupt font fixture not available" unless File.exist?(corrupt_font_path)

        expect do
          described_class.from_path(corrupt_font_path)
        end.to raise_error(Fontist::Errors::FontFileError,
                           /Table 'name' failed validation/)
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
