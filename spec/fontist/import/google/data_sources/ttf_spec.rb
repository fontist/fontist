require "spec_helper"
require "fontist/import/google/data_sources/ttf"

RSpec.describe Fontist::Import::Google::DataSources::Ttf do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "#initialize" do
    it "sets the api_key" do
      expect(client.api_key).to eq(api_key)
    end

    it "does not set a capability parameter" do
      expect(client.capability).to be_nil
    end
  end

  describe "#url" do
    it "generates URL without capability parameter" do
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
      expect(url).not_to include("capability")
    end
  end

  describe "#fetch" do
    it "returns an array of FontFamily models" do
      stub_google_fonts_api(:ttf) do
        families = client.fetch
        expect(families).to be_an(Array)
        expect(families).not_to be_empty
        expect(families.first).to be_a(
          Fontist::Import::Google::Models::FontFamily
        )
      end
    end

    it "returns fonts with TTF file URLs" do
      stub_google_fonts_api(:ttf) do
        families = client.fetch
        family = families.first
        url = family.file_urls.first
        expect(url).to end_with(".ttf")
      end
    end

    it "parses font family metadata correctly" do
      stub_google_fonts_api(:ttf) do
        families = client.fetch
        family = families.first
        expect(family.family).not_to be_nil
        expect(family.variants).to be_an(Array)
        expect(family.version).not_to be_nil
        expect(family.category).not_to be_nil
      end
    end

    it "caches results on subsequent calls" do
      stub_google_fonts_api(:ttf) do
        first_result = client.fetch
        second_result = client.fetch
        expect(second_result).to equal(first_result)
      end
    end
  end

  describe "TTF-specific behavior" do
    it "fetches fonts in TTF format" do
      stub_google_fonts_api(:ttf) do
        families = client.fetch
        families.take(5).each do |family|
          family.file_urls.each do |url|
            expect(url).to match(/\.ttf$/)
          end
        end
      end
    end
  end
end