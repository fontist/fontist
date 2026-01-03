require "spec_helper"
require_relative "../../lib/fontist/macos_framework_metadata"

RSpec.describe Fontist::MacosFrameworkMetadata do
  describe ".metadata" do
    it "returns framework metadata as a hash" do
      metadata = described_class.metadata

      expect(metadata).to be_a(Hash)
      expect(metadata).to have_key(7)
      expect(metadata).to have_key(8)
    end
  end

  describe ".min_macos_version" do
    it "returns correct version for Font7" do
      expect(described_class.min_macos_version(7)).to eq("10.11")
    end

    it "returns correct version for Font8" do
      expect(described_class.min_macos_version(8)).to eq("26.0")
    end

    it "returns nil for unknown framework" do
      expect(described_class.min_macos_version(99)).to be_nil
    end
  end

  describe ".max_macos_version" do
    it "returns correct version for Font7" do
      expect(described_class.max_macos_version(7)).to eq("15.7")
    end

    it "returns nil for Font8" do
      expect(described_class.max_macos_version(8)).to be_nil
    end
  end

  describe ".parser_class" do
    it "returns correct parser class for Font7" do
      expect(described_class.parser_class(7)).to eq("Fontist::Macos::Catalog::Font7Parser")
    end

    it "returns correct parser class for Font8" do
      expect(described_class.parser_class(8)).to eq("Fontist::Macos::Catalog::Font8Parser")
    end
  end

  describe ".compatible_with_macos?" do
    it "returns true for compatible Font7 version" do
      expect(described_class.compatible_with_macos?(7, "12.0")).to be true
    end

    it "returns false for too old macOS version" do
      expect(described_class.compatible_with_macos?(7, "10.10")).to be false
    end

    it "returns false for too new macOS version" do
      expect(described_class.compatible_with_macos?(7, "16.0")).to be false
    end

    it "returns true for Font8 on Sequoia" do
      expect(described_class.compatible_with_macos?(8, "26.0")).to be true
    end

    it "returns false for Font8 on older macOS" do
      expect(described_class.compatible_with_macos?(8, "25.0")).to be false
    end

    it "returns false for unknown framework" do
      expect(described_class.compatible_with_macos?(99, "12.0")).to be false
    end
  end

  describe ".description" do
    it "returns correct description for Font7" do
      expect(described_class.description(7)).to eq("Font7 framework (macOS Monterey, Ventura, Sonoma)")
    end

    it "returns correct description for Font8" do
      expect(described_class.description(8)).to eq("Font8 framework (macOS Sequoia+)")
    end

    it "returns generic message for unknown framework" do
      expect(described_class.description(99)).to eq("Unknown framework 99")
    end
  end
end