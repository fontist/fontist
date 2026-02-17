require "spec_helper"
require "fontist/format_matcher"
require "fontist/format_spec"

RSpec.describe Fontist::FormatMatcher do
  let(:format_spec) { Fontist::FormatSpec.new }
  let(:matcher) { described_class.new(format_spec) }

  describe "constants" do
    it "defines desktop formats" do
      expect(described_class::DESKTOP_FORMATS)
        .to contain_exactly("ttf", "otf", "ttc", "otc", "dfont")
    end

    it "defines web formats" do
      expect(described_class::WEB_FORMATS).to contain_exactly("woff", "woff2")
    end

    it "defines all formats" do
      expect(described_class::ALL_FORMATS)
        .to match_array(described_class::DESKTOP_FORMATS + described_class::WEB_FORMATS)
    end
  end

  describe "#matches_resource?" do
    let(:resource) do
      double("Resource",
             format: "ttf",
             variable_font?: false,
             variable_axes: [])
    end

    context "with no constraints" do
      it "returns true" do
        expect(matcher.matches_resource?(resource)).to be true
      end
    end

    context "with format constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns false when format does not match" do
        expect(matcher.matches_resource?(resource)).to be false
      end

      it "returns true when format matches" do
        allow(resource).to receive(:format).and_return("woff2")

        expect(matcher.matches_resource?(resource)).to be true
      end
    end

    context "with variable font constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(prefer_variable: true) }

      it "returns false when resource is not variable" do
        expect(matcher.matches_resource?(resource)).to be false
      end

      it "returns true when resource is variable" do
        allow(resource).to receive(:variable_font?).and_return(true)

        expect(matcher.matches_resource?(resource)).to be true
      end
    end

    context "with variable axes constraint" do
      let(:format_spec) do
        Fontist::FormatSpec.new(variable_axes: ["wght", "wdth"])
      end
      let(:variable_resource) do
        double("Resource",
               format: "ttf",
               variable_font?: true,
               variable_axes: %w[wght wdth ital])
      end

      it "returns true when all required axes are available" do
        expect(matcher.matches_resource?(variable_resource)).to be true
      end

      it "returns false when required axes are missing" do
        allow(variable_resource).to receive(:variable_axes).and_return(["wght"])

        expect(matcher.matches_resource?(variable_resource)).to be false
      end
    end
  end

  describe "#matches_style?" do
    let(:style) do
      double("Style",
             formats: %w[ttf woff2],
             variable_font: false,
             variable_axes: [])
    end

    context "with no constraints" do
      it "returns true" do
        expect(matcher.matches_style?(style)).to be true
      end
    end

    context "with format constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns true when format is in style formats" do
        expect(matcher.matches_style?(style)).to be true
      end

      it "returns false when format is not in style formats" do
        allow(style).to receive(:formats).and_return(["ttf"])

        expect(matcher.matches_style?(style)).to be false
      end
    end

    context "with variable font constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(prefer_variable: true) }

      it "returns false when style is not variable" do
        expect(matcher.matches_style?(style)).to be false
      end

      it "returns true when style is variable" do
        allow(style).to receive(:variable_font).and_return(true)

        expect(matcher.matches_style?(style)).to be true
      end
    end
  end

  describe "#matches_indexed_font?" do
    let(:indexed_font) do
      double("IndexedFont",
             format: "ttf",
             variable_font: false,
             variable_axes: [])
    end

    context "with no constraints" do
      it "returns true" do
        expect(matcher.matches_indexed_font?(indexed_font)).to be true
      end
    end

    context "with format constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns false when format does not match" do
        expect(matcher.matches_indexed_font?(indexed_font)).to be false
      end

      it "returns true when format matches" do
        allow(indexed_font).to receive(:format).and_return("woff2")

        expect(matcher.matches_indexed_font?(indexed_font)).to be true
      end
    end

    context "with variable font constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(prefer_variable: true) }

      it "returns false when font is not variable" do
        expect(matcher.matches_indexed_font?(indexed_font)).to be false
      end

      it "returns true when font is variable" do
        allow(indexed_font).to receive(:variable_font).and_return(true)

        expect(matcher.matches_indexed_font?(indexed_font)).to be true
      end
    end
  end

  describe "#filter_resources" do
    let(:resource1) do
      double("Resource", format: "ttf", variable_font?: false, variable_axes: [])
    end
    let(:resource2) do
      double("Resource", format: "woff2", variable_font?: false, variable_axes: [])
    end
    let(:resources) { [["ttf_res", resource1], ["woff2_res", resource2]] }

    context "with no constraints" do
      it "returns all resources" do
        expect(matcher.filter_resources(resources)).to eq(resources)
      end
    end

    context "with format constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns only matching resources" do
        result = matcher.filter_resources(resources)
        expect(result).to eq([["woff2_res", resource2]])
      end
    end
  end

  describe "#filter_styles" do
    let(:style1) { double("Style", formats: ["ttf"], variable_font: false, variable_axes: []) }
    let(:style2) { double("Style", formats: ["woff2"], variable_font: false, variable_axes: []) }
    let(:styles) { [style1, style2] }

    context "with no constraints" do
      it "returns all styles" do
        expect(matcher.filter_styles(styles)).to eq(styles)
      end
    end

    context "with format constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns only matching styles" do
        result = matcher.filter_styles(styles)
        expect(result).to eq([style2])
      end
    end
  end

  describe "#filter_indexed_fonts" do
    let(:font1) { double("IndexedFont", format: "ttf", variable_font: false, variable_axes: []) }
    let(:font2) { double("IndexedFont", format: "woff2", variable_font: false, variable_axes: []) }
    let(:fonts) { [font1, font2] }

    context "with no constraints" do
      it "returns all fonts" do
        expect(matcher.filter_indexed_fonts(fonts)).to eq(fonts)
      end
    end

    context "with format constraint" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns only matching fonts" do
        result = matcher.filter_indexed_fonts(fonts)
        expect(result).to eq([font2])
      end
    end
  end

  describe "#select_preferred_resource" do
    let(:static_ttf) do
      double("Resource", format: "ttf", variable_font?: false, variable_axes: [])
    end
    let(:static_woff2) do
      double("Resource", format: "woff2", variable_font?: false, variable_axes: [])
    end
    let(:variable_ttf) do
      double("Resource", format: "ttf", variable_font?: true, variable_axes: ["wght"])
    end
    let(:resources) do
      [
        ["static_ttf", static_ttf],
        ["static_woff2", static_woff2],
        ["variable_ttf", variable_ttf],
      ]
    end

    context "with empty resources" do
      it "returns nil" do
        expect(matcher.select_preferred_resource([])).to be_nil
      end
    end

    context "with no constraints" do
      it "returns first resource" do
        expect(matcher.select_preferred_resource(resources)).to eq(resources.first)
      end
    end

    context "with prefer_format" do
      let(:format_spec) { Fontist::FormatSpec.new(prefer_format: "woff2") }

      it "returns resource with preferred format" do
        result = matcher.select_preferred_resource(resources)
        expect(result).to eq(["static_woff2", static_woff2])
      end
    end

    context "with prefer_variable" do
      let(:format_spec) { Fontist::FormatSpec.new(prefer_variable: true) }

      it "returns variable resource" do
        result = matcher.select_preferred_resource(resources)
        expect(result).to eq(["variable_ttf", variable_ttf])
      end
    end
  end

  describe "#installation_strategy" do
    context "when no format specified" do
      it "returns install strategy with first available format" do
        result = matcher.installation_strategy(%w[ttf otf woff2])

        expect(result[:strategy]).to eq(:install)
        expect(result[:format]).to eq("ttf")
      end
    end

    context "when format is available" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns install strategy with requested format" do
        result = matcher.installation_strategy(%w[ttf woff2 otf])

        expect(result[:strategy]).to eq(:install)
        expect(result[:format]).to eq("woff2")
      end
    end

    context "when format is not available but can be converted" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "woff2") }

      it "returns convert strategy" do
        result = matcher.installation_strategy(%w[ttf otf])

        expect(result[:strategy]).to eq(:convert)
        expect(result[:from]).to eq("ttf")
        expect(result[:to]).to eq("woff2")
      end
    end

    context "when format is not available and cannot be converted" do
      let(:format_spec) { Fontist::FormatSpec.new(format: "ttf") }

      it "returns unavailable strategy" do
        result = matcher.installation_strategy(%w[woff woff2])

        expect(result[:strategy]).to eq(:unavailable)
        expect(result[:requested]).to eq("ttf")
        expect(result[:available]).to eq(%w[woff woff2])
      end
    end
  end

  describe ".can_convert?" do
    it "converts from desktop to web formats" do
      expect(described_class.can_convert?("ttf", "woff")).to be true
      expect(described_class.can_convert?("ttf", "woff2")).to be true
      expect(described_class.can_convert?("otf", "woff")).to be true
      expect(described_class.can_convert?("otf", "woff2")).to be true
    end

    it "does not convert from web to desktop formats" do
      expect(described_class.can_convert?("woff", "ttf")).to be false
      expect(described_class.can_convert?("woff2", "otf")).to be false
    end

    it "does not convert between same category formats" do
      expect(described_class.can_convert?("ttf", "otf")).to be false
      expect(described_class.can_convert?("woff", "woff2")).to be false
    end

    it "returns false for nil formats" do
      expect(described_class.can_convert?(nil, "woff2")).to be false
      expect(described_class.can_convert?("ttf", nil)).to be false
      expect(described_class.can_convert?(nil, nil)).to be false
    end
  end

  describe "#can_convert?" do
    it "delegates to class method" do
      expect(matcher.can_convert?("ttf", "woff2")).to be true
      expect(matcher.can_convert?("woff2", "ttf")).to be false
    end
  end
end
