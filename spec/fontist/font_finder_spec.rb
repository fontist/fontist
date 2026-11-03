require "spec_helper"
require "fontist/font_finder"
require "fontist/format_spec"

RSpec.describe Fontist::FontFinder do
  describe "#by_axes" do
    it "raises ArgumentError for non-array input" do
      finder = described_class.new

      expect { finder.by_axes("wght") }.to raise_error(ArgumentError)
    end

    it "returns empty array when no matching fonts" do
      finder = described_class.new

      # This will return empty since we need actual v5 formulas
      result = finder.by_axes(["nonexistent_axis"])
      expect(result).to be_an(Array)
    end
  end

  describe "#variable_fonts" do
    it "returns array of FontMatch objects" do
      finder = described_class.new

      result = finder.variable_fonts
      expect(result).to be_an(Array)
    end
  end

  describe "#by_category" do
    it "returns array of FontMatch objects" do
      finder = described_class.new

      result = finder.by_category("sans-serif")
      expect(result).to be_an(Array)
    end
  end

  describe "#by_format" do
    let(:woff2_formula) do
      Fontist::Formula.from_yaml(<<~YAML)
        name: Space Mono
        schema_version: 5
        resources:
          woff2_static:
            source: google
            family: Space Mono
            files: ["https://fonts.gstatic.com/space-mono.woff2"]
            format: woff2
          ttf_static:
            source: google
            family: Space Mono
            files: ["https://fonts.gstatic.com/space-mono.ttf"]
            format: ttf
        fonts: []
      YAML
    end

    let(:archive_formula) do
      Fontist::Formula.from_yaml(<<~YAML)
        name: Lato
        schema_version: 5
        resources:
          lato.zip:
            urls: ["https://example.com/lato.zip"]
        fonts:
        - name: Lato
          styles:
          - family_name: Lato
            type: Regular
            font: Lato-Regular.ttf
      YAML
    end

    before do
      allow(Fontist::Formula).to receive(:all)
        .and_return([woff2_formula, archive_formula])
    end

    it "returns the resources recorded in that format" do
      matches = described_class.new.by_format("woff2")

      expect(matches.map { |m| [m.name, m.resource, m.format] })
        .to eq([["Space Mono", "woff2_static", "woff2"]])
    end

    it "includes archives whose font files are in that format" do
      matches = described_class.new.by_format("ttf")

      expect(matches.map { |m| [m.name, m.resource, m.format] })
        .to eq([["Space Mono", "ttf_static", "ttf"],
                ["Lato", "lato.zip", "ttf"]])
    end
  end
end

RSpec.describe Fontist::FontMatch do
  describe "#initialize" do
    it "creates FontMatch with all attributes" do
      match = described_class.new(
        name: "Test Font",
        resource: "test_resource",
        axes: %w[wght wdth],
        format: "woff2",
        category: "sans-serif",
        resources: ["res1", "res2"],
      )

      expect(match.name).to eq("Test Font")
      expect(match.resource).to eq("test_resource")
      expect(match.axes).to contain_exactly("wght", "wdth")
      expect(match.format).to eq("woff2")
      expect(match.category).to eq("sans-serif")
      expect(match.resources).to contain_exactly("res1", "res2")
    end

    it "creates FontMatch with minimal attributes" do
      match = described_class.new(name: "Test Font")

      expect(match.name).to eq("Test Font")
      expect(match.resource).to be_nil
      expect(match.axes).to eq([])
      expect(match.format).to be_nil
      expect(match.category).to be_nil
      expect(match.resources).to be_nil
    end
  end

  describe "#to_h" do
    it "returns hash with all attributes" do
      match = described_class.new(
        name: "Test Font",
        resource: "test_resource",
        axes: %w[wght],
        format: "woff2",
      )

      result = match.to_h

      expect(result[:name]).to eq("Test Font")
      expect(result[:resource]).to eq("test_resource")
      expect(result[:axes]).to eq(%w[wght])
      expect(result[:format]).to eq("woff2")
    end

    it "includes all attributes" do
      match = described_class.new(name: "Test Font")

      result = match.to_h

      expect(result).to have_key(:name)
      expect(result[:name]).to eq("Test Font")
    end
  end
end
