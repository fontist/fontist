require "spec_helper"

RSpec.describe Fontist::Import::Models::FontMetadata do
  describe "initialization" do
    it "creates instance with all attributes" do
      metadata = described_class.new(
        family_name: "Test Family",
        subfamily_name: "Regular",
        full_name: "Test Family Regular",
        postscript_name: "TestFamily-Regular",
        preferred_family_name: "Test",
        preferred_subfamily_name: "Book",
        version: "1.0.0",
        copyright: "Copyright (c) 2024",
        description: "Test description",
        vendor_url: "https://example.com",
        license_url: "https://example.com/license",
        font_format: "truetype",
        is_variable: false,
      )

      expect(metadata.family_name).to eq("Test Family")
      expect(metadata.subfamily_name).to eq("Regular")
      expect(metadata.full_name).to eq("Test Family Regular")
      expect(metadata.postscript_name).to eq("TestFamily-Regular")
      expect(metadata.preferred_family_name).to eq("Test")
      expect(metadata.preferred_subfamily_name).to eq("Book")
      expect(metadata.version).to eq("1.0.0")
      expect(metadata.copyright).to eq("Copyright (c) 2024")
      expect(metadata.description).to eq("Test description")
      expect(metadata.vendor_url).to eq("https://example.com")
      expect(metadata.license_url).to eq("https://example.com/license")
      expect(metadata.font_format).to eq("truetype")
      expect(metadata.is_variable).to eq(false)
    end

    it "handles nil values gracefully" do
      metadata = described_class.new(
        family_name: "Test Family",
        subfamily_name: "Regular",
      )

      expect(metadata.family_name).to eq("Test Family")
      expect(metadata.subfamily_name).to eq("Regular")
      expect(metadata.preferred_family_name).to be_nil
      expect(metadata.version).to be_nil
      expect(metadata.description).to be_nil
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON correctly" do
      metadata = described_class.new(
        family_name: "Test Family",
        subfamily_name: "Regular",
        full_name: "Test Family Regular",
        version: "1.0.0",
      )

      json = metadata.to_json
      parsed = JSON.parse(json)

      expect(parsed["family_name"]).to eq("Test Family")
      expect(parsed["subfamily_name"]).to eq("Regular")
      expect(parsed["full_name"]).to eq("Test Family Regular")
      expect(parsed["version"]).to eq("1.0.0")
    end

    it "deserializes from JSON correctly" do
      json_data = {
        "family_name" => "Test Family",
        "subfamily_name" => "Regular",
        "full_name" => "Test Family Regular",
        "version" => "1.0.0",
        "is_variable" => true,
      }.to_json

      metadata = described_class.from_json(json_data)

      expect(metadata.family_name).to eq("Test Family")
      expect(metadata.subfamily_name).to eq("Regular")
      expect(metadata.full_name).to eq("Test Family Regular")
      expect(metadata.version).to eq("1.0.0")
      expect(metadata.is_variable).to eq(true)
    end
  end
end
