require "spec_helper"
require_relative "../../lib/fontist/sil_import_source"

RSpec.describe Fontist::SilImportSource do
  describe "#differentiation_key" do
    it "returns version" do
      source = described_class.new(
        version: "1.0",
        release_date: "2024-01-01"
      )

      expect(source.differentiation_key).to eq("1.0")
    end
  end

  describe "#outdated?" do
    it "detects older version" do
      old_source = described_class.new(
        version: "1.0",
        release_date: "2024-01-01"
      )

      new_source = described_class.new(
        version: "2.0",
        release_date: "2024-06-01"
      )

      expect(old_source.outdated?(new_source)).to be true
    end

    it "returns false when compared to non-SilImportSource" do
      source = described_class.new(
        version: "1.0",
        release_date: "2024-01-01"
      )

      expect(source.outdated?(double)).to be false
    end
  end

  describe "#to_s" do
    it "returns human-readable string" do
      source = described_class.new(
        version: "1.0",
        release_date: "2024-01-01"
      )

      expect(source.to_s).to eq("SIL Fonts (version: 1.0, released: 2024-01-01)")
    end
  end

  describe "serialization" do
    it "serializes to YAML correctly" do
      source = described_class.new(
        version: "1.0",
        release_date: "2024-01-01"
      )

      yaml = source.to_yaml
      expect(yaml).to include("version: '1.0'")
      expect(yaml).to include("release_date: '2024-01-01'")
    end
  end
end