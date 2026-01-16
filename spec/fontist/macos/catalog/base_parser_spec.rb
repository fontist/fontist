require "spec_helper"
require_relative "../../../../lib/fontist/macos/catalog/base_parser"

RSpec.describe Fontist::Macos::Catalog::BaseParser do
  let(:xml_path) do
    "spec/fixtures/macos_catalogs/com_apple_MobileAsset_Font6.xml"
  end

  subject(:parser) { described_class.new(xml_path) }

  describe "#initialize" do
    it "accepts xml_path parameter" do
      expect(parser.xml_path).to eq(xml_path)
    end
  end

  describe "#assets" do
    it "returns array of Asset objects" do
      assets = parser.assets

      expect(assets).to be_an(Array)
      expect(assets).not_to be_empty
      expect(assets.first).to be_a(Fontist::Macos::Catalog::Asset)
    end

    it "parses all assets from catalog" do
      assets = parser.assets

      # Font6 catalog should have multiple assets
      expect(assets.size).to be > 0
    end
  end

  describe "#catalog_version" do
    context "with Font6 catalog" do
      it "extracts version number from filename" do
        expect(parser.catalog_version).to eq(6)
      end
    end

    context "with Font7 catalog" do
      let(:xml_path) do
        "spec/fixtures/macos_catalogs/com_apple_MobileAsset_Font7.xml"
      end

      it "extracts version 7" do
        expect(parser.catalog_version).to eq(7)
      end
    end

    context "with Font8 catalog" do
      let(:xml_path) do
        "spec/fixtures/macos_catalogs/com_apple_MobileAsset_Font8.xml"
      end

      it "extracts version 8" do
        expect(parser.catalog_version).to eq(8)
      end
    end
  end

  describe "parsing behavior" do
    it "memoizes parsed data" do
      # Data parsing should be memoized (Plist.parse_xml called once)
      expect(Plist).to receive(:parse_xml).once.and_call_original

      # First call parses
      parser.assets

      # Second call should use memoized data
      parser.assets
    end

    it "handles missing Assets key gracefully" do
      # If XML doesn't have Assets key, should return empty array
      allow(parser).to receive(:data).and_return({})

      expect(parser.assets).to eq([])
    end
  end
end
