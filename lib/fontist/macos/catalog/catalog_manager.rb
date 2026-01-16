require_relative "font3_parser"
require_relative "font4_parser"
require_relative "font5_parser"
require_relative "font6_parser"
require_relative "font7_parser"
require_relative "font8_parser"
require "open-uri"
require "uri"

module Fontist
  module Macos
    module Catalog
      # Manages macOS Font catalogs across different versions
      # Provides discovery, version detection, and parser selection
      # Catalogs are downloaded from Apple's servers
      class CatalogManager
        # Catalog URLs for different versions
        CATALOG_URLS = {
          3 => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font3/com_apple_MobileAsset_Font3.xml",
          4 => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font4/com_apple_MobileAsset_Font4.xml",
          5 => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font5/com_apple_MobileAsset_Font5.xml",
          6 => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml",
          7 => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml",
          8 => "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml",
        }.freeze

        class << self
          def available_catalogs
            downloaded_catalogs
          end

          # Get path to catalog cache directory
          def catalog_cache_path
            @catalog_cache_path ||= Fontist.fontist_version_path.join("macos_catalogs").tap do |path|
              FileUtils.mkdir_p(path) unless path.exist?
            end
          end

          # Download a catalog for a specific version if not already cached
          def download_catalog(version, cache_path: nil)
            cache_dir = cache_path || catalog_cache_path

            # Check if catalog is already cached
            cached_catalog = Dir.glob("#{cache_dir}/com_apple_MobileAsset_Font#{version}/*.xml").first
            return cached_catalog if cached_catalog

            # Download the catalog
            url = CATALOG_URLS[version]
            unless url
              raise ArgumentError,
                    "Unsupported Font catalog version: #{version}. Supported versions: 3, 4, 5, 6, 7, 8"
            end

            version_dir = File.join(cache_dir,
                                    "com_apple_MobileAsset_Font#{version}")
            FileUtils.mkdir_p(version_dir)

            catalog_file = File.join(version_dir,
                                     File.basename(URI.parse(url).path))

            Fontist.ui.say("Downloading Font#{version} catalog from #{url}...") if Fontist.ui.respond_to?(:say)

            URI(url).open(
              "User-Agent" => "Fontist/#{Fontist::VERSION}",
            ) do |response|
              File.write(catalog_file, response.read)
            end

            catalog_file
          rescue ArgumentError
            # Re-raise ArgumentError (unsupported version) as-is
            raise
          rescue StandardError => e
            # For other errors (network issues, etc.), return nil
            Fontist.ui.error("Failed to download Font#{version} catalog: #{e.message}") if Fontist.ui.respond_to?(:error)
            nil
          end

          # Get all downloaded catalogs from cache
          def downloaded_catalogs
            Dir.glob("#{catalog_cache_path}/com_apple_MobileAsset_Font*/*.xml").sort
          end

          def parser_for(catalog_path)
            version = detect_version(catalog_path)

            case version
            when 3
              Font3Parser.new(catalog_path)
            when 4
              Font4Parser.new(catalog_path)
            when 5
              Font5Parser.new(catalog_path)
            when 6
              Font6Parser.new(catalog_path)
            when 7
              Font7Parser.new(catalog_path)
            when 8
              Font8Parser.new(catalog_path)
            else
              raise ArgumentError,
                    "Unsupported Font catalog version: #{version}. " \
                    "Supported versions: 3, 4, 5, 6, 7, 8"
            end
          end

          def detect_version(catalog_path)
            # Extract version from directory name or filename
            # e.g., /path/com_apple_MobileAsset_Font7/file.xml -> 7
            match = catalog_path.match(/Font(\d+)/)

            unless match
              raise ArgumentError,
                    "Cannot detect version from: #{catalog_path}"
            end

            match[1].to_i
          end

          def all_assets
            available_catalogs.flat_map do |catalog_path|
              parser_for(catalog_path).assets
            end
          end

          def latest_catalog
            available_catalogs.last
          end

          def catalog_for_version(version)
            catalog = available_catalogs.find do |path|
              path.include?("Font#{version}")
            end

            # If catalog not found locally or in cache, download it
            catalog ||= download_catalog(version)

            catalog
          end
        end
      end
    end
  end
end
