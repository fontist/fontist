# frozen_string_literal: true

# Test helper for setting up macOS font catalogs in tests
#
# This helper provides methods to copy catalogs from spec/fixtures/macos_catalogs to test directories
module MacosCatalogHelper
  # Path to the directory containing downloaded catalogs
  CATALOGS_SOURCE_DIR = File.expand_path("../fixtures/macos_catalogs",
                                         __dir__).freeze

  # Copy catalogs to a test directory
  #
  # @param target_dir [String] The target directory (will create macos_catalogs subdirectory)
  # @return [String] The path to the catalogs directory
  def self.setup_catalogs(target_dir)
    catalogs_dir = File.join(target_dir, "macos_catalogs")
    FileUtils.mkdir_p(catalogs_dir)

    # Copy each catalog to its version subdirectory
    Dir.glob(File.join(CATALOGS_SOURCE_DIR,
                       "com_apple_MobileAsset_Font*.xml")).each do |catalog_file|
      # Extract version number from filename
      version = catalog_file.match(/Font(\d+)\.xml/)[1]

      # Create version subdirectory
      version_dir = File.join(catalogs_dir,
                              "com_apple_MobileAsset_Font#{version}")
      FileUtils.mkdir_p(version_dir)

      # Copy catalog file
      target_file = File.join(version_dir, File.basename(catalog_file))
      FileUtils.cp(catalog_file, target_file) unless File.exist?(target_file)
    end

    catalogs_dir
  end

  # Check if source catalogs exist
  #
  # @return [Boolean] true if catalogs are available
  def self.catalogs_available?
    Dir.glob(File.join(CATALOGS_SOURCE_DIR,
                       "com_apple_MobileAsset_Font*.xml")).any?
  end

  # Get path to a specific catalog in the source directory
  #
  # @param version [Integer] The catalog version (3-8)
  # @return [String, nil] The path to the catalog or nil if not found
  def self.catalog_path(version)
    Dir.glob(File.join(CATALOGS_SOURCE_DIR,
                       "com_apple_MobileAsset_Font#{version}.xml")).first
  end
end
