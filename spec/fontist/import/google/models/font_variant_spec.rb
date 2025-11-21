require "spec_helper"
require "fontist/import/google/models/font_variant"
require "fontist/import/google/models/font_family"

RSpec.describe Fontist::Import::Google::Models::FontVariant do
  describe "JSON serialization" do
    let(:ttf_variant_json) do
      {
        "name" => "regular",
        "url" => "https://fonts.gstatic.com/s/abeezee/v23/test.ttf",
        "format" => "ttf",
      }.to_json
    end

    let(:woff2_variant_json) do
      {
        "name" => "italic",
        "url" => "https://fonts.gstatic.com/s/abeezee/v23/test.woff2",
        "format" => "woff2",
      }.to_json
    end

    it "deserializes TTF variant from JSON" do
      variant = described_class.from_json(ttf_variant_json)

      expect(variant.name).to eq("regular")
      expect(variant.url).to match(/\.ttf$/)
      expect(variant.format).to eq("ttf")
    end

    it "deserializes WOFF2 variant from JSON" do
      variant = described_class.from_json(woff2_variant_json)

      expect(variant.name).to eq("italic")
      expect(variant.url).to match(/\.woff2$/)
      expect(variant.format).to eq("woff2")
    end

    it "round-trips through JSON serialization" do
      original = described_class.from_json(ttf_variant_json)
      json = original.to_json
      deserialized = described_class.from_json(json)

      expect(deserialized.name).to eq(original.name)
      expect(deserialized.url).to eq(original.url)
      expect(deserialized.format).to eq(original.format)
    end
  end

  describe "#variable_font?" do
    let(:variable_family) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "AR One Sans",
        axes: [
          Fontist::Import::Google::Models::Axis.new(
            tag: "wght", start: 100, end: 900
          ),
        ],
      )
    end

    let(:static_family) do
      Fontist::Import::Google::Models::FontFamily.new(
        family: "ABeeZee",
      )
    end

    it "returns true when parent family has axes" do
      variant = described_class.new(
        name: "regular",
        url: "https://example.com/font.ttf",
        format: "ttf",
      )

      expect(variant.variable_font?(variable_family)).to be true
    end

    it "returns false when parent family has no axes" do
      variant = described_class.new(
        name: "regular",
        url: "https://example.com/font.ttf",
        format: "ttf",
      )

      expect(variant.variable_font?(static_family)).to be false
    end

    it "returns false when no family provided" do
      variant = described_class.new(
        name: "regular",
        url: "https://example.com/font.ttf",
        format: "ttf",
      )

      expect(variant.variable_font?).to be false
    end
  end

  describe "#extension" do
    it "returns .ttf for TTF format" do
      variant = described_class.new(
        name: "regular",
        url: "https://example.com/font.ttf",
        format: "ttf",
      )

      expect(variant.extension).to eq(".ttf")
    end

    it "returns .woff2 for WOFF2 format" do
      variant = described_class.new(
        name: "regular",
        url: "https://example.com/font.woff2",
        format: "woff2",
      )

      expect(variant.extension).to eq(".woff2")
    end

    it "returns empty string for unknown format" do
      variant = described_class.new(
        name: "regular",
        url: "https://example.com/font.abc",
        format: "abc",
      )

      expect(variant.extension).to eq("")
    end
  end

  describe "#ttf?" do
    it "returns true for TTF format" do
      variant = described_class.new(format: "ttf")
      expect(variant.ttf?).to be true
    end

    it "returns false for WOFF2 format" do
      variant = described_class.new(format: "woff2")
      expect(variant.ttf?).to be false
    end
  end

  describe "#woff2?" do
    it "returns true for WOFF2 format" do
      variant = described_class.new(format: "woff2")
      expect(variant.woff2?).to be true
    end

    it "returns false for TTF format" do
      variant = described_class.new(format: "ttf")
      expect(variant.woff2?).to be false
    end
  end

  describe "#description" do
    it "returns human-readable description" do
      variant = described_class.new(
        name: "regular",
        format: "ttf",
      )

      expect(variant.description).to eq("regular (ttf)")
    end

    it "includes different formats" do
      variant = described_class.new(
        name: "italic",
        format: "woff2",
      )

      expect(variant.description).to eq("italic (woff2)")
    end
  end

  describe "#valid_format?" do
    it "returns true for TTF format" do
      variant = described_class.new(format: "ttf")
      expect(variant.valid_format?).to be true
    end

    it "returns true for WOFF2 format" do
      variant = described_class.new(format: "woff2")
      expect(variant.valid_format?).to be true
    end

    it "returns false for invalid format" do
      variant = described_class.new(format: "invalid")
      expect(variant.valid_format?).to be false
    end
  end

  describe "real-world examples from API" do
    it "handles ABeeZee regular variant" do
      variant = described_class.from_json(
        {
          "name" => "regular",
          "url" => "https://fonts.gstatic.com/s/abeezee/v23/esDR31xSG-6AGleN6tKukbcHCpE.ttf",
          "format" => "ttf",
        }.to_json,
      )

      expect(variant.name).to eq("regular")
      expect(variant.ttf?).to be true
      expect(variant.valid_format?).to be true
    end

    it "handles ABeeZee italic variant in WOFF2" do
      variant = described_class.from_json(
        {
          "name" => "italic",
          "url" => "https://fonts.gstatic.com/s/abeezee/v23/esDT31xSG-6AGleN2tCkkJUCGpG-GQ.woff2",
          "format" => "woff2",
        }.to_json,
      )

      expect(variant.name).to eq("italic")
      expect(variant.woff2?).to be true
      expect(variant.valid_format?).to be true
    end
  end
end