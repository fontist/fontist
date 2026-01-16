require "spec_helper"
require_relative "../../../../lib/fontist/macos/catalog/catalog_manager"
require_relative "../../../support/macos_catalog_helper"

RSpec.describe Fontist::Macos::Catalog::CatalogManager do
  # Clean up the class-level cache path instance variable between tests
  after(:each) do
    # Reset the cache path instance variable so next test gets a fresh one
    cache_path = described_class.catalog_cache_path
    described_class.remove_instance_variable(:@catalog_cache_path) if described_class.instance_variable_defined?(:@catalog_cache_path)

    # Clean up downloaded catalog files to avoid polluting other tests
    FileUtils.rm_rf(cache_path) if cache_path&.exist?
  end

  # Skip all tests if catalogs are not available
  before(:each) do
    skip "Catalogs not available. Run: rake download_macos_catalogs" unless MacosCatalogHelper.catalogs_available?
  end

  describe ".available_catalogs" do
    it "returns an array" do
      catalogs = described_class.available_catalogs
      expect(catalogs).to be_an(Array)
    end

    it "returns sorted results" do
      catalogs = described_class.available_catalogs
      expect(catalogs).to eq(catalogs.sort)
    end

    it "returns catalogs from cache" do
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:error)

      # Download a catalog first
      described_class.download_catalog(6)

      catalogs = described_class.available_catalogs

      expect(catalogs).not_to be_empty
      expect(catalogs.first).to include("Font6")
    end
  end

  describe ".detect_version" do
    it "extracts version from Font6 path" do
      path = "/System/Library/AssetsV2/com_apple_MobileAsset_Font6/catalog.xml"
      expect(described_class.detect_version(path)).to eq(6)
    end

    it "extracts version from Font7 path" do
      path = "/path/to/com_apple_MobileAsset_Font7/catalog.xml"
      expect(described_class.detect_version(path)).to eq(7)
    end

    it "extracts version from Font8 path" do
      path = "/path/to/com_apple_MobileAsset_Font8/catalog.xml"
      expect(described_class.detect_version(path)).to eq(8)
    end
  end

  describe ".parser_for" do
    it "returns Font7Parser for Font7 catalog" do
      path = "/path/to/com_apple_MobileAsset_Font7/catalog.xml"
      parser = described_class.parser_for(path)

      expect(parser).to be_a(Fontist::Macos::Catalog::Font7Parser)
    end

    it "returns Font8Parser for Font8 catalog" do
      path = "/path/to/com_apple_MobileAsset_Font8/catalog.xml"
      parser = described_class.parser_for(path)

      expect(parser).to be_a(Fontist::Macos::Catalog::Font8Parser)
    end

    it "raises error for unsupported versions" do
      path = "/path/to/com_apple_MobileAsset_Font99/catalog.xml"

      expect do
        described_class.parser_for(path)
      end.to raise_error(/Unsupported Font catalog version: 99/)
    end
  end

  describe ".all_assets", skip_unless_macos: true do
    before do
      # Set up catalogs in the Fontist home directory for this test
      MacosCatalogHelper.setup_catalogs(Fontist.fontist_version_path.to_s)
    end

    it "aggregates assets from all available catalogs" do
      assets = described_class.all_assets

      expect(assets).to be_an(Array)
      expect(assets).not_to be_empty
      expect(assets.first).to be_a(Fontist::Macos::Catalog::Asset)
    end
  end

  describe ".download_catalog" do
    include_context "fresh home"

    it "downloads and caches a catalog for the specified version" do
      # Use stubbed UI to avoid actual output during test
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:error)

      # Test downloading Font6 catalog
      catalog_path = described_class.download_catalog(6)

      expect(catalog_path).to be_a(String)
      expect(File.exist?(catalog_path)).to be true
      expect(catalog_path).to include("com_apple_MobileAsset_Font6")
      expect(catalog_path).to include(".xml")
    end

    it "returns cached catalog on subsequent calls" do
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:error)

      # First call downloads
      first_path = described_class.download_catalog(7)
      # Second call should return cached version
      second_path = described_class.download_catalog(7)

      expect(first_path).to eq(second_path)
    end

    it "raises error for unsupported version" do
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:error)

      expect do
        described_class.download_catalog(99)
      end.to raise_error(/Unsupported Font catalog version: 99/)
    end
  end

  describe ".catalog_for_version" do
    include_context "fresh home"

    it "downloads catalog if not found locally" do
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:error)

      # On non-macOS, local catalogs won't exist, so it should download
      catalog = described_class.catalog_for_version(8)

      expect(catalog).to be_a(String)
      expect(File.exist?(catalog)).to be true
      expect(catalog).to include("Font8")
    end
  end

  describe ".catalog_cache_path" do
    include_context "fresh home"

    it "returns a valid path in the fontist directory" do
      cache_path = described_class.catalog_cache_path

      expect(cache_path).to be_a(Pathname)
      expect(cache_path.exist?).to be true
      expect(cache_path.to_s).to include("macos_catalogs")
    end
  end

  describe ".downloaded_catalogs" do
    include_context "fresh home"

    it "returns empty array when no catalogs are downloaded" do
      # Reset the cache path to ensure a fresh start
      described_class.remove_instance_variable(:@catalog_cache_path) if described_class.instance_variable_defined?(:@catalog_cache_path)

      catalogs = described_class.downloaded_catalogs

      expect(catalogs).to be_an(Array)
      expect(catalogs).to be_empty
    end

    it "returns downloaded catalogs" do
      allow(Fontist.ui).to receive(:say)
      allow(Fontist.ui).to receive(:error)

      # Download a catalog
      described_class.download_catalog(5)

      catalogs = described_class.downloaded_catalogs

      expect(catalogs).to be_an(Array)
      expect(catalogs).not_to be_empty
      expect(catalogs.first).to include("Font5")
    end
  end
end
