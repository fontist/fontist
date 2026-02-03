require "spec_helper"
require_relative "../../../../lib/fontist/macos/catalog/font8_parser"

RSpec.describe Fontist::Macos::Catalog::Font8Parser do
  describe "inheritance" do
    it "inherits from BaseParser" do
      expect(described_class.superclass).to eq(Fontist::Macos::Catalog::BaseParser)
    end
  end

  describe "#parse_assets with PlatformDelivery filtering" do
    let(:parser) { described_class.new("com_apple_MobileAsset_Font8.xml") }

    let(:mock_assets) do
      [
        {
          "__BaseURL" => "https://example.com/",
          "__RelativePath" => "macos_font.zip",
          "FontInfo4" => [{ "PostScriptFontName" => "macOS-Font" }],
          "PlatformDelivery" => ["macOS-download", "iOS-download"],
        },
        {
          "__BaseURL" => "https://example.com/",
          "__RelativePath" => "ios_only_font.zip",
          "FontInfo4" => [{ "PostScriptFontName" => "iOS-Only" }],
          "PlatformDelivery" => ["iOS-download"],
        },
        {
          "__BaseURL" => "https://example.com/",
          "__RelativePath" => "invisible_font.zip",
          "FontInfo4" => [{ "PostScriptFontName" => "Invisible" }],
          "PlatformDelivery" => ["macOS-invisible"],
        },
        {
          "__BaseURL" => "https://example.com/",
          "__RelativePath" => "no_platform_font.zip",
          "FontInfo4" => [{ "PostScriptFontName" => "Universal" }],
          "PlatformDelivery" => nil,
        },
      ]
    end

    before do
      allow(parser).to receive(:data).and_return({
                                                   "Assets" => mock_assets,
                                                   "postedDate" => "2024-08-13T18:11:00Z",
                                                 })
    end

    it "includes assets with macOS-download in PlatformDelivery" do
      assets = parser.assets

      names = assets.map(&:postscript_names).flatten
      expect(names).to include("macOS-Font")
    end

    it "excludes assets with only iOS in PlatformDelivery" do
      assets = parser.assets

      names = assets.map(&:postscript_names).flatten
      expect(names).not_to include("iOS-Only")
    end

    it "excludes assets with macOS-invisible" do
      assets = parser.assets

      names = assets.map(&:postscript_names).flatten
      expect(names).not_to include("Invisible")
    end

    it "includes assets with nil PlatformDelivery" do
      assets = parser.assets

      names = assets.map(&:postscript_names).flatten
      expect(names).to include("Universal")
    end
  end

  describe "#macos_compatible?" do
    let(:parser) { described_class.new("dummy.xml") }

    it "returns true for assets with macOS-download" do
      asset = { "PlatformDelivery" => ["macOS-download"] }
      expect(parser.send(:macos_compatible?, asset)).to be true
    end

    it "returns true for assets with multiple platforms including macOS" do
      asset = { "PlatformDelivery" => ["iOS-download", "macOS-download",
                                       "watchOS-download"] }
      expect(parser.send(:macos_compatible?, asset)).to be true
    end

    it "returns false for assets with macOS-invisible" do
      asset = { "PlatformDelivery" => ["macOS-invisible"] }
      expect(parser.send(:macos_compatible?, asset)).to be false
    end

    it "returns false for assets with only iOS" do
      asset = { "PlatformDelivery" => ["iOS-download"] }
      expect(parser.send(:macos_compatible?, asset)).to be false
    end

    it "returns true for assets with nil PlatformDelivery" do
      asset = { "PlatformDelivery" => nil }
      expect(parser.send(:macos_compatible?, asset)).to be true
    end

    it "returns true for assets without PlatformDelivery key" do
      asset = {}
      expect(parser.send(:macos_compatible?, asset)).to be true
    end
  end
end
