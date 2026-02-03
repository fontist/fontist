require "spec_helper"
require "fontist/import/sil_import"

RSpec.describe "Fontist::Import::SilImport", slow: true, dev: true do
  let(:formulas_repo_path) { Pathname.new(create_tmp_dir) }

  let(:fonts_under_test) { ["Apparatus SIL"] }

  it "finds archive links and calls CreateFormula" do
    VCR.use_cassette("sil_import") do
      require "fontist/import/sil_import"

      allow(Fontist).to receive(:formulas_repo_path)
        .and_return(formulas_repo_path)

      Dir.mktmpdir do |index_dir|
        allow(Fontist).to receive(:formula_index_dir)
          .and_return(Pathname.new(index_dir))

        allow_any_instance_of(Fontist::Import::SilImport)
          .to receive(:font_links).and_wrap_original do |m, *args|
            m.call(*args).select do |tag|
              fonts_under_test.include?(tag.content)
            end
          end

        received_count = 0
        allow_any_instance_of(Fontist::Import::CreateFormula)
          .to receive(:call) { received_count += 1 }

        # Test with new interface
        importer = Fontist::Import::SilImport.new
        result = importer.call

        expect(received_count).to be 1
        expect(result).to be_a(Hash)
        expect(result[:successful]).to eq(1)

        expect(Fontist.formulas_path.join("sil")).to exist
      end
    end
  end
end

RSpec.describe Fontist::Import::SilImport do
  subject(:importer) { described_class.new }

  describe "#initialize" do
    it "accepts no options (backward compatible)" do
      importer = described_class.new
      expect(importer.send(:formula_dir)).to be_a(Pathname)
    end

    it "accepts output_path option" do
      importer = described_class.new(output_path: "/tmp/test")
      expect(importer.send(:formula_dir).to_s).to eq("/tmp/test")
    end

    it "accepts font_name option" do
      importer = described_class.new(font_name: "Charis")
      expect(importer.instance_variable_get(:@font_name)).to eq("Charis")
    end

    it "accepts verbose option" do
      importer = described_class.new(verbose: true)
      expect(importer.instance_variable_get(:@verbose)).to be true
    end
  end

  describe "#filter_by_name" do
    let(:links) do
      [
        double("Link", content: "Charis SIL"),
        double("Link", content: "Andika"),
        double("Link", content: "Apparatus SIL"),
      ]
    end

    it "filters links by font name (case insensitive)" do
      importer = described_class.new(font_name: "charis")
      filtered = importer.send(:filter_by_name, links)
      expect(filtered.size).to eq(1)
      expect(filtered.first.content).to eq("Charis SIL")
    end

    it "returns multiple matches if applicable" do
      importer = described_class.new(font_name: "sil")
      filtered = importer.send(:filter_by_name, links)
      expect(filtered.size).to eq(2)
    end
  end

  describe "#extract_version_from_url" do
    it "extracts version from standard SIL URL format" do
      url = "https://software.sil.org/downloads/r/charis/CharisSIL-6.200.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("6.200")
    end

    it "extracts version from URL with dash separator" do
      url = "https://example.com/fonts/Andika-6.101.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("6.101")
    end

    it "extracts version from URL with underscore separator" do
      url = "https://example.com/fonts/Font_1.5.2.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("1.5.2")
    end

    it "extracts two-part version" do
      url = "https://example.com/fonts/Font-2.1.tar.gz"
      expect(importer.send(:extract_version_from_url, url)).to eq("2.1")
    end

    it "handles version with 'v' prefix" do
      url = "https://example.com/fonts/Font-v3.0.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("3.0")
    end

    it "returns nil when no version found" do
      url = "https://example.com/fonts/SomeFont.zip"
      expect(importer.send(:extract_version_from_url, url)).to be_nil
    end
  end

  describe "#create_import_source" do
    it "creates SilImportSource with version and timestamp" do
      source = importer.send(:create_import_source, "6.200")

      expect(source).to be_a(Fontist::SilImportSource)
      expect(source.version).to eq("6.200")
      expect(source.release_date).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "returns nil when version is nil" do
      source = importer.send(:create_import_source, nil)
      expect(source).to be_nil
    end

    it "creates import_source with differentiation_key" do
      source = importer.send(:create_import_source, "1.5.0")
      expect(source.differentiation_key).to eq("1.5.0")
    end
  end

  describe "#call" do
    it "returns results hash" do
      importer = described_class.new
      allow(importer).to receive(:font_links).and_return([])

      result = importer.call

      expect(result).to be_a(Hash)
      expect(result).to have_key(:successful)
      expect(result).to have_key(:failed)
      expect(result).to have_key(:duration)
      expect(result).to have_key(:errors)
    end
  end
end
