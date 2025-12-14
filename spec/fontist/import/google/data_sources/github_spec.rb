require "spec_helper"
require "fontist/import/google/data_sources/github"

RSpec.describe Fontist::Import::Google::DataSources::Github do
  let(:fixture_path) { File.join(__dir__, "../../../../fixtures/google") }
  let(:source) { described_class.new(source_path: fixture_path) }

  describe "#initialize" do
    it "sets the source_path" do
      expect(source.source_path.to_s).to include("fixtures/google")
    end

    context "with invalid source path" do
      it "raises error for non-existent path" do
        expect do
          described_class.new(source_path: "/non/existent/path")
        end.to raise_error(ArgumentError, /does not exist/)
      end

      it "raises error for non-directory path" do
        file_path = File.join(fixture_path, "DESCRIPTION.en_us.html")
        expect do
          described_class.new(source_path: file_path)
        end.to raise_error(ArgumentError, /not a directory/)
      end
    end
  end

  describe "#fetch" do
    it "returns an array" do
      families = source.fetch
      expect(families).to be_an(Array)
    end

    it "returns FontFamily models" do
      families = source.fetch
      expect(families).to all(
        be_a(Fontist::Import::Google::Models::FontFamily),
      )
    end

    it "caches results on subsequent calls" do
      first_result = source.fetch
      second_result = source.fetch
      expect(second_result).to equal(first_result)
    end

    it "parses family metadata" do
      families = source.fetch
      family = families.first

      expect(family.family).to eq("Roboto")
      expect(family.designer).to eq("Google")
      expect(family.license).to eq("Apache-2.0")
      expect(family.category).to eq("sans-serif")
    end

    it "extracts variants" do
      families = source.fetch
      family = families.first

      expect(family.variants).to be_an(Array)
      expect(family.variants).not_to be_empty
      expect(family.variants).to include("regular")
    end

    it "extracts subsets" do
      families = source.fetch
      family = families.first

      expect(family.subsets).to be_an(Array)
      expect(family.subsets).to include("latin")
    end
  end

  describe "#fetch_family" do
    it "finds family by name" do
      family = source.fetch_family("Roboto")
      expect(family).not_to be_nil
      expect(family.family).to eq("Roboto")
    end

    it "returns nil for non-existent family" do
      family = source.fetch_family("NonExistentFont12345")
      expect(family).to be_nil
    end

    it "handles case-insensitive names" do
      family = source.fetch_family("ROBOTO")
      expect(family).not_to be_nil
      expect(family.family).to eq("Roboto")
    end
  end

  describe "#clear_cache" do
    it "clears the cached result" do
      first_result = source.fetch
      expect(first_result).not_to be_nil

      source.clear_cache

      second_result = source.fetch
      expect(second_result).not_to equal(first_result)
    end
  end

  describe "metadata parsing" do
    it "extracts designer information" do
      families = source.fetch
      family = families.first

      expect(family.designer).to eq("Google")
    end

    it "normalizes license names" do
      families = source.fetch
      family = families.first

      expect(family.license).to eq("Apache-2.0")
    end

    it "normalizes category names" do
      families = source.fetch
      family = families.first

      expect(family.category).to eq("sans-serif")
    end

    it "reads license text if available" do
      families = source.fetch
      family = families.first

      # May or may not have license text depending on fixtures
      if family.license_text
        expect(family.license_text).to be_a(String)
        expect(family.license_text).not_to be_empty
      end
    end

    it "reads description if available" do
      families = source.fetch
      family = families.first

      # May or may not have description depending on fixtures
      if family.description
        expect(family.description).to be_a(String)
        expect(family.description).not_to be_empty
      end
    end
  end

  describe "variant name generation" do
    let(:font_400_normal) { { weight: 400, style: "normal" } }
    let(:font_400_italic) { { weight: 400, style: "italic" } }
    let(:font_700_normal) { { weight: 700, style: "normal" } }
    let(:font_700_italic) { { weight: 700, style: "italic" } }

    it "generates 'regular' for 400 normal" do
      variant = source.send(:variant_name, 400, "normal")
      expect(variant).to eq("regular")
    end

    it "generates 'italic' for 400 italic" do
      variant = source.send(:variant_name, 400, "italic")
      expect(variant).to eq("italic")
    end

    it "generates weight for non-400 normal" do
      variant = source.send(:variant_name, 700, "normal")
      expect(variant).to eq("700")
    end

    it "generates weight+style for non-400 italic" do
      variant = source.send(:variant_name, 700, "italic")
      expect(variant).to eq("700italic")
    end
  end

  describe "category normalization" do
    it "normalizes SANS_SERIF to sans-serif" do
      category = source.send(:normalize_category, "SANS_SERIF")
      expect(category).to eq("sans-serif")
    end

    it "normalizes SERIF to serif" do
      category = source.send(:normalize_category, "SERIF")
      expect(category).to eq("serif")
    end

    it "normalizes DISPLAY to display" do
      category = source.send(:normalize_category, "DISPLAY")
      expect(category).to eq("display")
    end

    it "normalizes HANDWRITING to handwriting" do
      category = source.send(:normalize_category, "HANDWRITING")
      expect(category).to eq("handwriting")
    end

    it "normalizes MONOSPACE to monospace" do
      category = source.send(:normalize_category, "MONOSPACE")
      expect(category).to eq("monospace")
    end

    it "returns nil for nil input" do
      category = source.send(:normalize_category, nil)
      expect(category).to be_nil
    end
  end

  describe "license normalization" do
    it "normalizes APACHE2 to Apache-2.0" do
      license = source.send(:normalize_license, "APACHE2")
      expect(license).to eq("Apache-2.0")
    end

    it "normalizes OFL to OFL-1.1" do
      license = source.send(:normalize_license, "OFL")
      expect(license).to eq("OFL-1.1")
    end

    it "normalizes UFL to UFL-1.0" do
      license = source.send(:normalize_license, "UFL")
      expect(license).to eq("UFL-1.0")
    end

    it "returns nil for nil input" do
      license = source.send(:normalize_license, nil)
      expect(license).to be_nil
    end
  end
end
