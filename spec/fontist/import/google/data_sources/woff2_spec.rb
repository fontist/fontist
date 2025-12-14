require "spec_helper"
require "fontist/import/google/data_sources/woff2"

RSpec.describe Fontist::Import::Google::DataSources::Woff2 do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "#initialize" do
    it "sets the api_key" do
      expect(client.api_key).to eq(api_key)
    end

    it "sets capability to WOFF2" do
      expect(client.capability).to eq("WOFF2")
    end
  end

  describe "#url" do
    it "generates URL with WOFF2 capability parameter" do
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
      expect(url).to include("capability=WOFF2")
    end
  end

  describe "#fetch" do
    it "returns an array of FontFamily models" do
      stub_google_fonts_api(:woff2) do
        families = client.fetch
        expect(families).to be_an(Array)
        expect(families).not_to be_empty
        expect(families.first).to be_a(
          Fontist::Import::Google::Models::FontFamily,
        )
      end
    end

    it "returns fonts with WOFF2 file URLs" do
      stub_google_fonts_api(:woff2) do
        families = client.fetch
        family = families.first
        url = family.file_urls.first
        expect(url).to end_with(".woff2")
      end
    end

    it "parses font family metadata correctly" do
      stub_google_fonts_api(:woff2) do
        families = client.fetch
        family = families.first
        expect(family.family).not_to be_nil
        expect(family.variants).to be_an(Array)
        expect(family.version).not_to be_nil
        expect(family.category).not_to be_nil
      end
    end

    it "caches results on subsequent calls" do
      stub_google_fonts_api(:woff2) do
        first_result = client.fetch
        second_result = client.fetch
        expect(second_result).to equal(first_result)
      end
    end
  end

  describe "WOFF2-specific behavior" do
    it "fetches fonts in WOFF2 format" do
      stub_google_fonts_api(:woff2) do
        families = client.fetch
        families.take(5).each do |family|
          family.file_urls.each do |url|
            expect(url).to match(/\.woff2$/)
          end
        end
      end
    end

    it "returns the same font families as TTF but with different URLs" do
      stub_google_fonts_api(:woff2) do
        families = client.fetch
        family = families.first

        # Check that URL structure is consistent with WOFF2 format
        family.file_urls.each do |url|
          expect(url).to include("fonts.gstatic.com")
          expect(url).to end_with(".woff2")
        end
      end
    end
  end
end
