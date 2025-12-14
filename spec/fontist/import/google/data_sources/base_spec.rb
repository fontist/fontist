require "spec_helper"
require "fontist/import/google/data_sources/base"

RSpec.describe Fontist::Import::Google::DataSources::Base do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "#initialize" do
    it "sets the api_key" do
      expect(client.api_key).to eq(api_key)
    end

    it "sets capability to nil by default" do
      expect(client.capability).to be_nil
    end

    it "accepts a capability parameter" do
      client = described_class.new(api_key: api_key, capability: "VF")
      expect(client.capability).to eq("VF")
    end
  end

  describe "#url" do
    it "returns the base URL with api_key parameter" do
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
    end

    it "includes capability parameter when set" do
      client = described_class.new(api_key: api_key, capability: "VF")
      url = client.url
      expect(url).to include("capability=VF")
    end

    it "does not include capability parameter when nil" do
      url = client.url
      expect(url).not_to include("capability")
    end
  end

  describe "#fetch_raw", vcr: { cassette_name: "google_fonts/ttf_sample" } do
    it "fetches and parses JSON from the API" do
      data = client.fetch_raw
      expect(data).to be_a(Hash)
      expect(data).to have_key("kind")
      expect(data).to have_key("items")
      expect(data["kind"]).to eq("webfonts#webfontList")
    end

    it "returns an array of items" do
      data = client.fetch_raw
      expect(data["items"]).to be_an(Array)
      expect(data["items"].length).to be > 0
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

    it "parses items into FontFamily models" do
      families = client.parse_response(raw_data)
      expect(families).to be_an(Array)
      expect(families.length).to eq(1)
      expect(families.first).to be_a(
        Fontist::Import::Google::Models::FontFamily,
      )
    end

    it "correctly parses font family attributes" do
      families = client.parse_response(raw_data)
      family = families.first
      expect(family.family).to eq("Test Family")
      expect(family.variants).to eq(["regular", "italic"])
      expect(family.version).to eq("v1")
      expect(family.category).to eq("sans-serif")
    end

    it "handles empty items array" do
      data = { "kind" => "webfonts#webfontList", "items" => [] }
      families = client.parse_response(data)
      expect(families).to eq([])
    end

    it "handles missing items key" do
      data = { "kind" => "webfonts#webfontList" }
      families = client.parse_response(data)
      expect(families).to eq([])
    end
  end

  describe "#fetch", vcr: { cassette_name: "google_fonts/ttf_sample" } do
    it "returns an array of FontFamily models" do
      families = client.fetch
      expect(families).to be_an(Array)
      expect(families.first).to be_a(
        Fontist::Import::Google::Models::FontFamily,
      )
    end

    it "caches the result" do
      first_result = client.fetch
      second_result = client.fetch
      expect(second_result).to equal(first_result)
    end

    it "returns at least one font family" do
      families = client.fetch
      expect(families.length).to be > 0
    end
  end

  describe "#clear_cache" do
    it "clears the cached result",
       vcr: { cassette_name: "google_fonts/ttf_sample" } do
      first_result = client.fetch
      client.clear_cache
      second_result = client.fetch
      expect(second_result).not_to equal(first_result)
    end

    it "returns nil" do
      expect(client.clear_cache).to be_nil
    end
  end
end
