require "spec_helper"
require "fontist/import/google/data_sources/ttf"

RSpec.describe Fontist::Import::Google::DataSources::Ttf do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "TTF data source" do
    it "initializes, generates URLs, fetches TTF fonts, and caches results" do
      # Test initialization
      expect(client.api_key).to eq(api_key)
      expect(client.capability).to be_nil

      # Test URL generation
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
      expect(url).not_to include("capability")

      # Test API interaction (single stub call)
      stub_google_fonts_api(:ttf) do
        families = client.fetch

        # Verify returns FontFamily models
        expect(families).to be_an(Array)
        expect(families).not_to be_empty
        expect(families.first).to be_a(Fontist::Import::Google::Models::FontFamily)

        # Verify TTF format
        family = families.first
        expect(family.family).not_to be_nil
        expect(family.variants).to be_an(Array)
        expect(family.version).not_to be_nil
        expect(family.category).not_to be_nil

        # Verify all URLs are TTF format
        families.take(5).each do |f|
          f.file_urls.each do |url|
            expect(url).to match(/\.ttf$/)
          end
        end

        # Verify caching works
        second_result = client.fetch
        expect(second_result).to equal(families)
      end
    end
  end
end
