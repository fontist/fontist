require "spec_helper"
require_relative "../../../../lib/fontist/macos/catalog/font7_parser"

RSpec.describe Fontist::Macos::Catalog::Font7Parser do
  let(:xml_path) { "spec/fixtures/macos_catalogs/com_apple_MobileAsset_Font7.xml" }

  subject(:parser) { described_class.new(xml_path) }

  describe "inheritance" do
    it "inherits from BaseParser" do
      expect(described_class.superclass).to eq(Fontist::Macos::Catalog::BaseParser)
    end
  end

  describe "#assets" do
    it "returns all assets without filtering" do
      assets = parser.assets

      expect(assets).to be_an(Array)
      expect(assets).not_to be_empty
    end

    it "does not filter by PlatformDelivery" do
      # Font7 doesn't have PlatformDelivery filtering
      # All assets in Font7 are macOS-compatible by default
      assets = parser.assets

      # Should include all assets from the catalog
      expect(assets.size).to be > 0
    end
  end

  describe "Font7 specifics" do
    it "handles Font7 compatibility version" do
      assets = parser.assets

      # Font7 uses _CompatibilityVersion: 2
      # Assets should be parsed correctly
      expect(assets.first).to respond_to(:compatibility_version)
    end
  end
end