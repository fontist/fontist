require "spec_helper"

RSpec.describe Fontist::FontInstaller do
  describe "styles kept for a format request" do
    let(:formula) do
      Fontist::Formula.from_yaml(<<~YAML)
        name: Charis
        schema_version: 5
        resources:
          charis.zip:
            urls: ["https://example.com/charis.zip"]
            format: ttf
        fonts:
        - name: Charis
          styles:
          - family_name: Charis
            type: Regular
            font: Charis-Regular.ttf
            formats: [ttf]
          - family_name: Charis
            type: Bold
            font: Charis-Bold.ttf
            formats: [ttf]
      YAML
    end

    let(:styles) { formula.fonts.flat_map(&:styles) }
    let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

    subject(:kept) do
      described_class.new(formula, format_spec: format_spec)
        .send(:styles_in_requested_format, styles)
        .map(&:font)
    end

    it "keeps every style for conversion when none is in that format" do
      expect(kept).to eq(%w[Charis-Regular.ttf Charis-Bold.ttf])
    end

    context "when the format is already offered" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "ttf") }

      it "keeps the styles in that format" do
        expect(kept).to eq(%w[Charis-Regular.ttf Charis-Bold.ttf])
      end
    end

    context "when a variable font is requested" do
      let(:format_spec) do
        Fontist::FormatSpec.new(format: "ttf", prefer_variable: true)
      end

      it "keeps no static style" do
        expect(kept).to be_empty
      end
    end
  end
end
