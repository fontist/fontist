require "spec_helper"
require "fontist/import/google/data_sources/base"

RSpec.describe Fontist::Import::Google::DataSources::Base do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "#initialize" do
    it "sets the api_key and capability" do
      expect(client.api_key).to eq(api_key)
      expect(client.capability).to be_nil

      client_with_capability = described_class.new(api_key: api_key,
                                                   capability: "VF")
      expect(client_with_capability.capability).to eq("VF")
    end
  end

  describe "#url" do
    it "builds URL with api_key and optional capability parameter" do
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
      expect(url).not_to include("capability")

      client_with_capability = described_class.new(api_key: api_key,
                                                   capability: "VF")
      url_with_capability = client_with_capability.url
      expect(url_with_capability).to include("capability=VF")
    end
  end

  describe "#parse_response" do
    let(:raw_data) do
      {
        "kind" => "webfonts#webfontList",
        "items" => [
          {
            "family" => "Test Family",
            "variants" => ["regular", "italic"],
            "subsets" => ["latin"],
            "version" => "v1",
            "lastModified" => "2025-01-01",
            "files" => {
              "regular" => "https://example.com/font.ttf",
            },
            "category" => "sans-serif",
            "kind" => "webfonts#webfont",
            "menu" => "https://example.com/menu.ttf",
          },
        ],
      }
    end

    it "parses items into FontFamily models with correct attributes" do
      families = client.parse_response(raw_data)
      expect(families).to be_an(Array)
      expect(families.length).to eq(1)

      family = families.first
      expect(family).to be_a(Fontist::Import::Google::Models::FontFamily)
      expect(family.family).to eq("Test Family")
      expect(family.variants).to eq(["regular", "italic"])
      expect(family.version).to eq("v1")
      expect(family.category).to eq("sans-serif")
    end

    it "handles empty or missing items" do
      expect(client.parse_response({ "kind" => "webfonts#webfontList",
                                     "items" => [] })).to eq([])
      expect(client.parse_response({ "kind" => "webfonts#webfontList" })).to eq([])
    end
  end

  describe "API interaction",
           vcr: { cassette_name: "google_fonts/ttf_sample" } do
    it "fetches, parses, caches data and supports cache clearing" do
      # Test fetch_raw
      raw_data = client.fetch_raw
      expect(raw_data).to be_a(Hash)
      expect(raw_data).to have_key("kind")
      expect(raw_data).to have_key("items")
      expect(raw_data["kind"]).to eq("webfonts#webfontList")
      expect(raw_data["items"]).to be_an(Array)
      expect(raw_data["items"].length).to be > 0

      # Test fetch returns FontFamily models
      families = client.fetch
      expect(families).to be_an(Array)
      expect(families.length).to be > 0
      expect(families.first).to be_a(Fontist::Import::Google::Models::FontFamily)

      # Test caching works
      second_result = client.fetch
      expect(second_result).to equal(families) # Same object reference

      # Test clear_cache
      expect(client.clear_cache).to be_nil
      third_result = client.fetch
      expect(third_result).not_to equal(families) # Different object after clear
      expect(third_result.length).to eq(families.length) # But same data
    end
  end
end
