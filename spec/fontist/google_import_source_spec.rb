require "spec_helper"
require "fontist/google_import_source"

RSpec.describe Fontist::GoogleImportSource do
  describe "#differentiation_key" do
    it "returns nil - Google Fonts use simple filenames" do
      source = described_class.new(
        commit_id: "abc123def456789",
        api_version: "v1",
        last_modified: "2024-01-01T12:00:00Z",
        family_id: "roboto",
      )

      # Google Fonts is a live service, filenames are NOT versioned
      expect(source.differentiation_key).to be_nil
    end
  end

  describe "#outdated?" do
    it "returns true when commit_id is different" do
      old_source = described_class.new(
        commit_id: "abc123",
        api_version: "v1",
        last_modified: "2024-01-01T12:00:00Z",
        family_id: "roboto",
      )

      new_source = described_class.new(
        commit_id: "def456",
        api_version: "v1",
        last_modified: "2024-01-02T12:00:00Z",
        family_id: "roboto",
      )

      expect(old_source.outdated?(new_source)).to be true
    end

    it "returns false when commit_id is the same" do
      source1 = described_class.new(
        commit_id: "abc123",
        api_version: "v1",
        last_modified: "2024-01-01T12:00:00Z",
        family_id: "roboto",
      )

      source2 = described_class.new(
        commit_id: "abc123",
        api_version: "v1",
        last_modified: "2024-01-01T12:00:00Z",
        family_id: "roboto",
      )

      expect(source1.outdated?(source2)).to be false
    end

    it "returns false when comparing with different type" do
      google_source = described_class.new(
        commit_id: "abc123",
        api_version: "v1",
        last_modified: "2024-01-01T12:00:00Z",
        family_id: "roboto",
      )

      other_source = Fontist::MacosImportSource.new(
        framework_version: 7,
        posted_date: "2024-01-01T12:00:00Z",
        asset_id: "test123",
      )

      expect(google_source.outdated?(other_source)).to be false
    end
  end

  describe "#to_s" do
    it "returns a human-readable representation" do
      source = described_class.new(
        commit_id: "abc123def456789",
        api_version: "v1",
        last_modified: "2024-01-01T12:00:00Z",
        family_id: "roboto",
      )

      result = source.to_s
      expect(result).to include("Google Fonts")
      expect(result).to include("abc123d") # Short commit (7 chars)
      expect(result).to include("roboto")
      expect(result).to include("v1")
    end
  end
end
