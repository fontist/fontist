require "spec_helper"
require_relative "../../lib/fontist/macos_import_source"

RSpec.describe Fontist::MacosImportSource do
  describe "#differentiation_key" do
    it "returns lowercased asset_id" do
      source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10M1360"
      )

      expect(source.differentiation_key).to eq("10m1360")
    end

    it "returns nil when asset_id is nil" do
      source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: nil
      )

      expect(source.differentiation_key).to be_nil
    end
  end

  describe "#outdated?" do
    it "detects older posted_date" do
      old_source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      new_source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-14T18:11:00Z",
        asset_id: "10m1361"
      )

      expect(old_source.outdated?(new_source)).to be true
    end

    it "returns false for newer posted_date" do
      old_source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-14T18:11:00Z",
        asset_id: "10m1360"
      )

      new_source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1361"
      )

      expect(old_source.outdated?(new_source)).to be false
    end

    it "returns false when dates are equal" do
      source1 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      source2 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1361"
      )

      expect(source1.outdated?(source2)).to be false
    end

    it "returns false when compared to non-MacosImportSource" do
      source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      expect(source.outdated?(double)).to be false
    end

    it "returns false when posted_date is nil" do
      source1 = described_class.new(
        framework_version: 7,
        posted_date: nil,
        asset_id: "10m1360"
      )

      source2 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1361"
      )

      expect(source1.outdated?(source2)).to be false
    end
  end

  describe "#min_macos_version" do
    it "returns correct version for Font7" do
      source = described_class.new(framework_version: 7)
      expect(source.min_macos_version).to eq("10.11")
    end

    it "returns correct version for Font8" do
      source = described_class.new(framework_version: 8)
      expect(source.min_macos_version).to eq("26.0")
    end
  end

  describe "#max_macos_version" do
    it "returns correct version for Font7" do
      source = described_class.new(framework_version: 7)
      expect(source.max_macos_version).to eq("15.7")
    end

    it "returns nil for Font8 (no upper limit)" do
      source = described_class.new(framework_version: 8)
      expect(source.max_macos_version).to be_nil
    end
  end

  describe "#compatible_with_macos?" do
    it "returns true for compatible Font7 version" do
      source = described_class.new(framework_version: 7)
      expect(source.compatible_with_macos?("12.0")).to be true
    end

    it "returns false for too old macOS version" do
      source = described_class.new(framework_version: 7)
      expect(source.compatible_with_macos?("10.10")).to be false
    end

    it "returns false for too new macOS version" do
      source = described_class.new(framework_version: 7)
      expect(source.compatible_with_macos?("16.0")).to be false
    end

    it "returns true for Font8 on Sequoia" do
      source = described_class.new(framework_version: 8)
      expect(source.compatible_with_macos?("26.0")).to be true
    end
  end

  describe "#to_s" do
    it "returns human-readable string" do
      source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      expect(source.to_s).to eq("macOS Font7 (posted: 2024-08-13T18:11:00Z, asset: 10m1360)")
    end
  end

  describe "#parser_class" do
    it "returns correct parser class for Font7" do
      source = described_class.new(framework_version: 7)
      expect(source.parser_class).to eq("Fontist::Macos::Catalog::Font7Parser")
    end

    it "returns correct parser class for Font8" do
      source = described_class.new(framework_version: 8)
      expect(source.parser_class).to eq("Fontist::Macos::Catalog::Font8Parser")
    end
  end

  describe "#description" do
    it "returns correct description for Font7" do
      source = described_class.new(framework_version: 7)
      expect(source.description).to eq("Font7 framework (macOS Monterey, Ventura, Sonoma)")
    end
  end

  describe "serialization" do
    it "serializes to YAML correctly" do
      source = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      yaml = source.to_yaml
      expect(yaml).to include("framework_version: 7")
      expect(yaml).to include("posted_date: '2024-08-13T18:11:00Z'")
      expect(yaml).to include("asset_id: 10m1360")
    end

    it "deserializes from YAML correctly" do
      yaml = <<~YAML
        ---
        type: macos
        framework_version: 7
        posted_date: '2024-08-13T18:11:00Z'
        asset_id: 10m1360
      YAML

      source = described_class.from_yaml(yaml)
      expect(source.framework_version).to eq(7)
      expect(source.posted_date).to eq("2024-08-13T18:11:00Z")
      expect(source.asset_id).to eq("10m1360")
    end
  end

  describe "equality" do
    it "is equal when framework_version and asset_id match" do
      source1 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      source2 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      expect(source1).to eq(source2)
    end

    it "is not equal when asset_id differs" do
      source1 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360"
      )

      source2 = described_class.new(
        framework_version: 7,
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1361"
      )

      expect(source1).not_to eq(source2)
    end
  end
end