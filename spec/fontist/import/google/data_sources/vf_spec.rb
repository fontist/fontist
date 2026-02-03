require "spec_helper"
require "fontist/import/google/data_sources/vf"

RSpec.describe Fontist::Import::Google::DataSources::Vf do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "VF (Variable Fonts) data source" do
    it "initializes, generates URLs with VF capability, fetches variable and static fonts with axes, and caches results" do
      # Test initialization with VF capability
      expect(client.api_key).to eq(api_key)
      expect(client.capability).to eq("VF")

      # Test URL generation includes VF capability
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
      expect(url).to include("capability=VF")

      # Test API interaction (single stub call)
      stub_google_fonts_api(:vf) do
        families = client.fetch

        # Verify returns FontFamily models
        expect(families).to be_an(Array)
        expect(families).not_to be_empty
        expect(families.first).to be_a(Fontist::Import::Google::Models::FontFamily)

        # Verify TTF format
        family = families.first
        url = family.file_urls.first
        expect(url).to end_with(".ttf")

        # Verify mix of variable and static fonts
        variable_fonts = families.select(&:variable_font?)
        static_fonts = families.reject(&:variable_font?)
        expect(variable_fonts).not_to be_empty
        expect(static_fonts).not_to be_empty

        # Verify variable font axes parsing
        vf = variable_fonts.first
        expect(vf.axes).to be_an(Array)
        expect(vf.axes).not_to be_empty
        axis = vf.axes.first
        expect(axis).to be_a(Fontist::Import::Google::Models::Axis)
        expect(axis.tag).to be_a(String)
        expect(axis.tag.length).to eq(4)
        expect(axis.start).to be_a(Numeric)
        expect(axis.end).to be_a(Numeric)

        # Verify static fonts have no axes
        static_font = static_fonts.first
        expect(static_font.axes).to be_nil.or be_empty
        expect(static_font.variable_font?).to be false

        # Verify weight axes exist in some variable fonts
        fonts_with_weight = variable_fonts.select { |f| f.weight_axes.any? }
        expect(fonts_with_weight).not_to be_empty
        weight_axis = fonts_with_weight.first.weight_axes.first
        expect(weight_axis.tag).to eq("wght")

        # Verify multi-axis fonts exist
        multi_axis_fonts = variable_fonts.select { |f| f.axes_count > 1 }
        expect(multi_axis_fonts).not_to be_empty

        # Verify caching works
        second_result = client.fetch
        expect(second_result).to equal(families)
      end
    end
  end
end
