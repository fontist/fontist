require "spec_helper"

RSpec.describe Fontist::WindowsFodMetadata do
  before { described_class.reset_cache }
  after { described_class.reset_cache }

  describe ".metadata" do
    it "loads the YAML data" do
      data = described_class.metadata
      expect(data).to be_a(Hash)
      expect(data).to have_key("capabilities")
    end
  end

  describe ".all_capabilities" do
    it "returns all capability names" do
      caps = described_class.all_capabilities
      expect(caps).to be_an(Array)
      expect(caps.size).to be >= 20
      expect(caps).to include("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
      expect(caps).to include("Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0")
    end
  end

  describe ".all_font_names" do
    it "returns all font family names" do
      names = described_class.all_font_names
      expect(names).to be_an(Array)
      expect(names).to include("Meiryo")
      expect(names).to include("Arial Nova")
      expect(names).to include("Batang")
    end
  end

  describe ".fonts_for_capability" do
    it "returns fonts for a known capability" do
      fonts = described_class.fonts_for_capability("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
      expect(fonts).to be_a(Hash)
      expect(fonts).to have_key("Meiryo")
      expect(fonts["Meiryo"]["files"]).to include("Meiryo.ttc")
    end

    it "returns nil for an unknown capability" do
      fonts = described_class.fonts_for_capability("Language.Fonts.UNKNOWN~~~0.0.1.0")
      expect(fonts).to be_nil
    end
  end

  describe ".capability_for_font" do
    it "finds capability for a known font" do
      cap = described_class.capability_for_font("Meiryo")
      expect(cap).to eq("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
    end

    it "finds capability case-insensitively" do
      cap = described_class.capability_for_font("meiryo")
      expect(cap).to eq("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
    end

    it "returns nil for an unknown font" do
      cap = described_class.capability_for_font("NotARealFont")
      expect(cap).to be_nil
    end

    it "finds Pan-European fonts" do
      cap = described_class.capability_for_font("Arial Nova")
      expect(cap).to eq("Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0")
    end
  end

  describe ".description_for_capability" do
    it "returns the description" do
      desc = described_class.description_for_capability("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
      expect(desc).to eq("Japanese Supplemental Fonts")
    end

    it "returns nil for unknown capability" do
      desc = described_class.description_for_capability("Unknown")
      expect(desc).to be_nil
    end
  end
end
