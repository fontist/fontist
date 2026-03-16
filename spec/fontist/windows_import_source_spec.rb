require "spec_helper"

RSpec.describe Fontist::WindowsImportSource do
  subject(:source) do
    described_class.new(
      type: "windows",
      capability_name: "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0",
      min_windows_version: "10.0",
    )
  end

  describe "#differentiation_key" do
    it "returns the capability name" do
      expect(source.differentiation_key).to eq("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
    end

    it "returns nil when capability_name is nil" do
      source = described_class.new(type: "windows")
      expect(source.differentiation_key).to be_nil
    end
  end

  describe "#outdated?" do
    it "returns false for another WindowsImportSource" do
      other = described_class.new(
        type: "windows",
        capability_name: "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0",
        min_windows_version: "10.0",
      )
      expect(source.outdated?(other)).to be false
    end

    it "returns false for non-WindowsImportSource" do
      other = Fontist::MacosImportSource.new(type: "macos")
      expect(source.outdated?(other)).to be false
    end
  end

  describe "#to_s" do
    it "returns a readable string" do
      expect(source.to_s).to include("Windows FOD")
      expect(source.to_s).to include("Language.Fonts.Jpan")
      expect(source.to_s).to include("10.0")
    end
  end

  describe "#==" do
    it "is equal to another source with the same capability_name" do
      other = described_class.new(
        type: "windows",
        capability_name: "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0",
        min_windows_version: "11.0",
      )
      expect(source).to eq(other)
    end

    it "is not equal to a source with different capability_name" do
      other = described_class.new(
        type: "windows",
        capability_name: "Language.Fonts.Kore~~~und-KORE~0.0.1.0",
      )
      expect(source).not_to eq(other)
    end

    it "is not equal to a non-WindowsImportSource" do
      other = Fontist::MacosImportSource.new(type: "macos")
      expect(source).not_to eq(other)
    end
  end

  describe "attributes" do
    it "has a type of 'windows'" do
      expect(source.type).to eq("windows")
    end

    it "has a capability_name" do
      expect(source.capability_name).to eq("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
    end

    it "has a min_windows_version" do
      expect(source.min_windows_version).to eq("10.0")
    end
  end
end
