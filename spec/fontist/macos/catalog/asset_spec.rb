require "spec_helper"
require_relative "../../../../lib/fontist/macos/catalog/asset"

RSpec.describe Fontist::Macos::Catalog::Asset do
  describe "#initialize" do
    let(:asset_data) do
      {
        "__BaseURL" => "https://updates.cdn-apple.com/2022/mobileassets/071-13653/",
        "__RelativePath" => "com_apple_MobileAsset_Font7/701405507c8753373648c7a6541608e32ed089ec.zip",
        "FontInfo4" => [
          {
            "PostScriptFontName" => "AlBayan",
            "FontFamilyName" => "Al Bayan",
            "FontStyleName" => "Plain",
            "PreferredFamilyName" => nil,
            "PreferredStyleName" => nil,
          },
          {
            "PostScriptFontName" => "AlBayan-Bold",
            "FontFamilyName" => "Al Bayan",
            "FontStyleName" => "Bold",
          },
        ],
        "Build" => "10M1360",
        "_CompatibilityVersion" => 2,
        "FontDesignLanguages" => ["Arab"],
        "Prerequisite" => [],
      }
    end

    subject(:asset) { described_class.new(asset_data) }

    it "extracts base URL" do
      expect(asset.base_url).to eq("https://updates.cdn-apple.com/2022/mobileassets/071-13653/")
    end

    it "extracts relative path" do
      expect(asset.relative_path).to eq("com_apple_MobileAsset_Font7/701405507c8753373648c7a6541608e32ed089ec.zip")
    end

    it "extracts font info" do
      expect(asset.font_info).to be_an(Array)
      expect(asset.font_info.size).to eq(2)
    end

    it "extracts build number" do
      expect(asset.build).to eq("10M1360")
    end

    it "extracts compatibility version" do
      expect(asset.compatibility_version).to eq(2)
    end

    it "extracts design languages" do
      expect(asset.design_languages).to eq(["Arab"])
    end
  end

  describe "#download_url" do
    let(:asset_data) do
      {
        "__BaseURL" => "https://updates.cdn-apple.com/base/",
        "__RelativePath" => "fonts/AlBayan.zip",
        "FontInfo4" => [],
      }
    end

    subject(:asset) { described_class.new(asset_data) }

    it "constructs full download URL" do
      expect(asset.download_url).to eq("https://updates.cdn-apple.com/base/fonts/AlBayan.zip")
    end
  end

  describe "#fonts" do
    let(:asset_data) do
      {
        "__BaseURL" => "https://example.com/",
        "__RelativePath" => "font.zip",
        "FontInfo4" => [
          {
            "PostScriptFontName" => "Test-Regular",
            "FontFamilyName" => "Test",
            "FontStyleName" => "Regular",
          },
        ],
      }
    end

    subject(:asset) { described_class.new(asset_data) }

    it "returns array of FontInfo objects" do
      fonts = asset.fonts
      expect(fonts).to be_an(Array)
      expect(fonts.size).to eq(1)
      expect(fonts.first).to be_a(Fontist::Macos::Catalog::FontInfo)
    end
  end

  describe "#postscript_names" do
    let(:asset_data) do
      {
        "__BaseURL" => "https://example.com/",
        "__RelativePath" => "font.zip",
        "FontInfo4" => [
          { "PostScriptFontName" => "AlBayan" },
          { "PostScriptFontName" => "AlBayan-Bold" },
          { "PostScriptFontName" => nil },
        ],
      }
    end

    subject(:asset) { described_class.new(asset_data) }

    it "extracts all PostScript names" do
      expect(asset.postscript_names).to eq(["AlBayan", "AlBayan-Bold"])
    end

    it "excludes nil values" do
      expect(asset.postscript_names).not_to include(nil)
    end
  end

  describe "#font_families" do
    let(:asset_data) do
      {
        "__BaseURL" => "https://example.com/",
        "__RelativePath" => "font.zip",
        "FontInfo4" => [
          { "FontFamilyName" => "Al Bayan" },
          { "FontFamilyName" => "Al Bayan" },
          { "FontFamilyName" => "Another Font" },
        ],
      }
    end

    subject(:asset) { described_class.new(asset_data) }

    it "extracts unique font family names" do
      expect(asset.font_families).to eq(["Al Bayan", "Another Font"])
    end

    it "removes duplicates" do
      expect(asset.font_families.size).to eq(2)
    end
  end

  describe Fontist::Macos::Catalog::FontInfo do
    let(:font_data) do
      {
        "PostScriptFontName" => "AlBayan-Bold",
        "FontFamilyName" => "Al Bayan",
        "FontStyleName" => "Bold",
        "PreferredFamilyName" => "Al Bayan Pro",
        "PreferredStyleName" => "Bold",
      }
    end

    subject(:font_info) { described_class.new(font_data) }

    it "extracts PostScript name" do
      expect(font_info.postscript_name).to eq("AlBayan-Bold")
    end

    it "extracts font family name" do
      expect(font_info.font_family_name).to eq("Al Bayan")
    end

    it "extracts font style name" do
      expect(font_info.font_style_name).to eq("Bold")
    end

    it "extracts preferred family name" do
      expect(font_info.preferred_family_name).to eq("Al Bayan Pro")
    end

    it "extracts preferred style name" do
      expect(font_info.preferred_style_name).to eq("Bold")
    end

    context "with nil values" do
      let(:font_data) do
        {
          "PostScriptFontName" => "Test",
          "PreferredFamilyName" => nil,
        }
      end

      it "handles nil gracefully" do
        expect(font_info.preferred_family_name).to be_nil
      end
    end
  end
end
