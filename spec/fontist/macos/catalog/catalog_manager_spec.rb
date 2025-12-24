require "spec_helper"
require_relative "../../../../lib/fontist/macos/catalog/catalog_manager"

RSpec.describe Fontist::Macos::Catalog::CatalogManager do
  describe ".available_catalogs" do
    it "returns an array" do
      catalogs = described_class.available_catalogs
      expect(catalogs).to be_an(Array)
    end

    it "searches in standard macOS location", skip_unless_macos: true do
      # On macOS, should check /System/Library/AssetsV2/
      catalogs = described_class.available_catalogs

      catalogs.each do |path|
        expect(path).to include("/System/Library/AssetsV2/")
        expect(path).to match(/com_apple_MobileAsset_Font\d+/)
      end
    end

    it "returns sorted results" do
      catalogs = described_class.available_catalogs
      expect(catalogs).to eq(catalogs.sort)
    end
  end

  describe ".detect_version" do
    it "extracts version from Font6 path" do
      path = "/System/Library/AssetsV2/com_apple_MobileAsset_Font6/catalog.xml"
      expect(described_class.detect_version(path)).to eq(6)
    end

    it "extracts version from Font7 path" do
      path = "/path/to/com_apple_MobileAsset_Font7/catalog.xml"
      expect(described_class.detect_version(path)).to eq(7)
    end

    it "extracts version from Font8 path" do
      path = "/path/to/com_apple_MobileAsset_Font8/catalog.xml"
      expect(described_class.detect_version(path)).to eq(8)
    end
  end

  describe ".parser_for" do
    it "returns Font7Parser for Font7 catalog" do
      path = "/path/to/com_apple_MobileAsset_Font7/catalog.xml"
      parser = described_class.parser_for(path)

      expect(parser).to be_a(Fontist::Macos::Catalog::Font7Parser)
    end

    it "returns Font8Parser for Font8 catalog" do
      path = "/path/to/com_apple_MobileAsset_Font8/catalog.xml"
      parser = described_class.parser_for(path)

      expect(parser).to be_a(Fontist::Macos::Catalog::Font8Parser)
    end

    it "raises error for unsupported versions" do
      path = "/path/to/com_apple_MobileAsset_Font99/catalog.xml"

      expect do
        described_class.parser_for(path)
      end.to raise_error(/Unsupported Font catalog version: 99/)
    end
  end

  describe ".all_assets", skip_unless_macos: true do
    it "aggregates assets from all available catalogs" do
      skip "No catalogs available" if described_class.available_catalogs.empty?

      assets = described_class.all_assets

      expect(assets).to be_an(Array)
      expect(assets).not_to be_empty
      expect(assets.first).to be_a(Fontist::Macos::Catalog::Asset)
    end
  end
end

# RSpec configuration for platform-specific tests
RSpec.configure do |config|
  config.before(:each, skip_unless_macos: true) do
    skip "Test requires macOS" unless Fontist::Utils::System.user_os == :macos
  end
end