require "spec_helper"
require "fontist/import/google/data_sources/vf"

RSpec.describe Fontist::Import::Google::DataSources::Vf do
  let(:api_key) { ENV["GOOGLE_FONTS_API_KEY"] }
  let(:client) { described_class.new(api_key: api_key) }

  before do
    skip "GOOGLE_FONTS_API_KEY environment variable not set" unless api_key
  end

  describe "#initialize" do
    it "sets the api_key" do
      expect(client.api_key).to eq(api_key)
    end

    it "sets capability to VF" do
      expect(client.capability).to eq("VF")
    end
  end

  describe "#url" do
    it "generates URL with VF capability parameter" do
      url = client.url
      expect(url).to include("https://www.googleapis.com/webfonts/v1/webfonts")
      expect(url).to include("key=#{api_key}")
      expect(url).to include("capability=VF")
    end
  end

  describe "#fetch" do
    it "returns an array of FontFamily models" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        expect(families).to be_an(Array)
        expect(families).not_to be_empty
        expect(families.first).to be_a(
          Fontist::Import::Google::Models::FontFamily,
        )
      end
    end

    it "includes fonts with variable font axes" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        variable_fonts = families.select(&:variable_font?)
        expect(variable_fonts).not_to be_empty
      end
    end

    it "includes fonts without axes (static fonts)" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        static_fonts = families.reject(&:variable_font?)
        expect(static_fonts).not_to be_empty
      end
    end

    it "returns fonts with TTF file URLs" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        family = families.first
        url = family.file_urls.first
        expect(url).to end_with(".ttf")
      end
    end

    it "caches results on subsequent calls" do
      stub_google_fonts_api(:vf) do
        first_result = client.fetch
        second_result = client.fetch
        expect(second_result).to equal(first_result)
      end
    end
  end

  describe "variable font axes parsing" do
    it "parses axes for variable fonts" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        variable_fonts = families.select(&:variable_font?)

        vf = variable_fonts.first
        expect(vf.axes).to be_an(Array)
        expect(vf.axes).not_to be_empty

        axis = vf.axes.first
        expect(axis).to be_a(Fontist::Import::Google::Models::Axis)
        expect(axis.tag).to be_a(String)
        expect(axis.tag.length).to eq(4)
        expect(axis.start).to be_a(Numeric)
        expect(axis.end).to be_a(Numeric)
      end
    end

    it "correctly identifies fonts without axes" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        static_fonts = families.reject(&:variable_font?)

        static_font = static_fonts.first
        expect(static_font.axes).to be_nil.or be_empty
        expect(static_font.variable_font?).to be false
      end
    end
  end

  describe "standard axes" do
    it "can find weight axes" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        variable_fonts = families.select(&:variable_font?)

        fonts_with_weight = variable_fonts.select do |f|
          f.weight_axes.any?
        end

        expect(fonts_with_weight).not_to be_empty
        font = fonts_with_weight.first
        weight_axis = font.weight_axes.first
        expect(weight_axis.tag).to eq("wght")
      end
    end

    it "handles multiple axes" do
      stub_google_fonts_api(:vf) do
        families = client.fetch
        variable_fonts = families.select(&:variable_font?)

        multi_axis_fonts = variable_fonts.select do |f|
          f.axes_count > 1
        end

        expect(multi_axis_fonts).not_to be_empty
      end
    end
  end

  describe "VF-specific behavior" do
    it "returns a mix of variable and static fonts" do
      stub_google_fonts_api(:vf) do
        families = client.fetch

        has_variable = families.any?(&:variable_font?)
        has_static = families.any? { |f| !f.variable_font? }

        expect(has_variable).to be true
        expect(has_static).to be true
      end
    end
  end
end
