require "spec_helper"
require "fontist/import/google/models/axis"

RSpec.describe Fontist::Import::Google::Models::Axis do
  describe "JSON serialization" do
    let(:weight_axis_json) do
      {
        "tag" => "wght",
        "start" => 100,
        "end" => 900,
      }.to_json
    end

    let(:slant_axis_json) do
      {
        "tag" => "slnt",
        "start" => -14,
        "end" => 14,
      }.to_json
    end

    let(:custom_axis_json) do
      {
        "tag" => "ARRR",
        "start" => 10,
        "end" => 60,
      }.to_json
    end

    it "deserializes weight axis from JSON" do
      axis = described_class.from_json(weight_axis_json)

      expect(axis.tag).to eq("wght")
      expect(axis.start).to eq(100)
      expect(axis.end).to eq(900)
    end

    it "deserializes slant axis with negative values from JSON" do
      axis = described_class.from_json(slant_axis_json)

      expect(axis.tag).to eq("slnt")
      expect(axis.start).to eq(-14)
      expect(axis.end).to eq(14)
    end

    it "deserializes custom axis from JSON" do
      axis = described_class.from_json(custom_axis_json)

      expect(axis.tag).to eq("ARRR")
      expect(axis.start).to eq(10)
      expect(axis.end).to eq(60)
    end

    it "round-trips through JSON serialization" do
      original = described_class.from_json(weight_axis_json)
      json = original.to_json
      deserialized = described_class.from_json(json)

      expect(deserialized.tag).to eq(original.tag)
      expect(deserialized.start).to eq(original.start)
      expect(deserialized.end).to eq(original.end)
    end
  end

  describe "#weight_axis?" do
    it "returns true for wght tag" do
      axis = described_class.new(tag: "wght", start: 100, end: 900)
      expect(axis.weight_axis?).to be true
    end

    it "returns false for non-weight tags" do
      axis = described_class.new(tag: "wdth", start: 100, end: 200)
      expect(axis.weight_axis?).to be false
    end
  end

  describe "#width_axis?" do
    it "returns true for wdth tag" do
      axis = described_class.new(tag: "wdth", start: 100, end: 200)
      expect(axis.width_axis?).to be true
    end

    it "returns false for non-width tags" do
      axis = described_class.new(tag: "wght", start: 100, end: 900)
      expect(axis.width_axis?).to be false
    end
  end

  describe "#slant_axis?" do
    it "returns true for slnt tag" do
      axis = described_class.new(tag: "slnt", start: -14, end: 14)
      expect(axis.slant_axis?).to be true
    end

    it "returns false for non-slant tags" do
      axis = described_class.new(tag: "wght", start: 100, end: 900)
      expect(axis.slant_axis?).to be false
    end
  end

  describe "#custom_axis?" do
    it "returns true for custom tags" do
      axis = described_class.new(tag: "ARRR", start: 10, end: 60)
      expect(axis.custom_axis?).to be true
    end

    it "returns false for standard tags" do
      standard_tags = %w[wght wdth slnt ital opsz]
      standard_tags.each do |tag|
        axis = described_class.new(tag: tag, start: 0, end: 100)
        expect(axis.custom_axis?).to be false
      end
    end
  end

  describe "#range" do
    it "returns [start, end] as array" do
      axis = described_class.new(tag: "wght", start: 100, end: 900)
      expect(axis.range).to eq([100, 900])
    end

    it "handles negative values" do
      axis = described_class.new(tag: "slnt", start: -14, end: 14)
      expect(axis.range).to eq([-14, 14])
    end
  end

  describe "#description" do
    it "describes weight axis" do
      axis = described_class.new(tag: "wght", start: 100, end: 900)
      expect(axis.description).to eq("wght (weight): 100–900")
    end

    it "describes width axis" do
      axis = described_class.new(tag: "wdth", start: 100, end: 200)
      expect(axis.description).to eq("wdth (width): 100–200")
    end

    it "describes slant axis" do
      axis = described_class.new(tag: "slnt", start: -14, end: 14)
      expect(axis.description).to eq("slnt (slant): -14–14")
    end

    it "describes custom axis" do
      axis = described_class.new(tag: "ARRR", start: 10, end: 60)
      expect(axis.description).to eq("ARRR (custom): 10–60")
    end
  end

  describe "real-world examples from API" do
    it "handles AR One Sans ARRR axis" do
      axis = described_class.from_json(
        { "tag" => "ARRR", "start" => 10, "end" => 60 }.to_json,
      )

      expect(axis.custom_axis?).to be true
      expect(axis.range).to eq([10, 60])
    end

    it "handles Advent Pro width axis" do
      axis = described_class.from_json(
        { "tag" => "wdth", "start" => 100, "end" => 200 }.to_json,
      )

      expect(axis.width_axis?).to be true
      expect(axis.range).to eq([100, 200])
    end

    it "handles Afacad Flux weight axis with extended range" do
      axis = described_class.from_json(
        { "tag" => "wght", "start" => 100, "end" => 1000 }.to_json,
      )

      expect(axis.weight_axis?).to be true
      expect(axis.range).to eq([100, 1000])
    end
  end
end