require "rubygems"

module Fontist
  # Loads and provides access to macOS font framework metadata
  #
  # This class centralizes framework-specific information that was previously
  # stored in individual formulas, enabling proper separation of concerns.
  class MacosFrameworkMetadata
    METADATA = {
      3 => {
        "min_macos_version" => "10.12",
        "max_macos_version" => "10.12",
        "asset_path" => "/System/Library/Assets",
        "parser_class" => "Fontist::Macos::Catalog::Font3Parser",
        "description" => "Font3 framework (macOS Sierra)",
      },
      4 => {
        "min_macos_version" => "10.13",
        "max_macos_version" => "10.13",
        "asset_path" => "/System/Library/Assets",
        "parser_class" => "Fontist::Macos::Catalog::Font4Parser",
        "description" => "Font4 framework (macOS High Sierra)",
      },
      5 => {
        "min_macos_version" => "10.14",
        "max_macos_version" => "10.15",
        "asset_path" => "/System/Library/AssetsV2",
        "parser_class" => "Fontist::Macos::Catalog::Font5Parser",
        "description" => "Font5 framework (macOS Mojave, Catalina)",
      },
      6 => {
        "min_macos_version" => "10.15",
        "max_macos_version" => "11.99",
        "asset_path" => "/System/Library/AssetsV2",
        "parser_class" => "Fontist::Macos::Catalog::Font6Parser",
        "description" => "Font6 framework (macOS Catalina, Big Sur)",
      },
      7 => {
        "min_macos_version" => "12.0",
        "max_macos_version" => "15.99",
        "asset_path" => "/System/Library/AssetsV2",
        "parser_class" => "Fontist::Macos::Catalog::Font7Parser",
        "description" => "Font7 framework (macOS Monterey, Ventura, Sonoma, Sequoia)",
      },
      8 => {
        "min_macos_version" => "26.0",
        "max_macos_version" => nil,
        "asset_path" => "/System/Library/AssetsV2",
        "parser_class" => "Fontist::Macos::Catalog::Font8Parser",
        "description" => "Font8 framework (macOS Tahoe+)",
      },
    }.freeze

    class << self
      # Returns the framework metadata
      #
      # @return [Hash] The frameworks metadata
      def metadata
        METADATA
      end

      # Gets the minimum macOS version for a given framework
      #
      # @param framework_version [Integer] The framework version (7, 8, etc.)
      # @return [String, nil] The minimum macOS version string or nil
      def min_macos_version(framework_version)
        metadata.dig(framework_version, "min_macos_version")
      end

      # Gets the maximum macOS version for a given framework
      #
      # @param framework_version [Integer] The framework version (7, 8, etc.)
      # @return [String, nil] The maximum macOS version string or nil if unlimited
      def max_macos_version(framework_version)
        metadata.dig(framework_version, "max_macos_version")
      end

      # Gets the parser class name for a given framework
      #
      # @param framework_version [Integer] The framework version (7, 8, etc.)
      # @return [String] The fully qualified parser class name
      def parser_class(framework_version)
        metadata.dig(framework_version, "parser_class")
      end

      # Checks if a framework version is compatible with a specific macOS version
      #
      # @param framework_version [Integer] The framework version (7, 8, etc.)
      # @param macos_version [String] The macOS version to check
      # @return [Boolean] true if compatible
      def compatible_with_macos?(framework_version, macos_version)
        min_version = min_macos_version(framework_version)
        return false unless min_version

        version = Gem::Version.new(macos_version)
        min = Gem::Version.new(min_version)

        return false if version < min

        max_version = max_macos_version(framework_version)
        return true unless max_version

        max = Gem::Version.new(max_version)
        version <= max
      rescue StandardError => e
        Fontist.ui.error("Error checking macOS compatibility: #{e.message}")
        false
      end

      # Gets a description for a framework version
      #
      # @param framework_version [Integer] The framework version (7, 8, etc.)
      # @return [String] The description or a generic message if not found
      def description(framework_version)
        metadata.dig(framework_version,
                     "description") || "Unknown framework #{framework_version}"
      end

      # Gets the asset path for a given framework
      #
      # @param framework_version [Integer] The framework version (3, 4, 5, 6, 7, 8)
      # @return [String, nil] The asset path or nil if not found
      def asset_path(framework_version)
        metadata.dig(framework_version, "asset_path")
      end

      # Gets the system installation path for a given framework
      #
      # @param framework_version [Integer] The framework version (3, 4, 5, 6, 7, 8)
      # @return [String, nil] The full system installation path or nil if not found
      def system_install_path(framework_version)
        base = asset_path(framework_version)
        return nil unless base

        "#{base}/com_apple_MobileAsset_Font#{framework_version}"
      end

      # Determines which framework version to use for a given macOS version
      #
      # @param macos_version [String] The macOS version (e.g., "10.15", "12.0", "26.0")
      # @return [Integer, nil] The framework version number or nil if unsupported
      def framework_for_macos(macos_version)
        return nil unless macos_version

        Gem::Version.new(macos_version)

        # Search for compatible framework in reverse order (newest first)
        metadata.keys.sort.reverse.each do |framework_version|
          if compatible_with_macos?(framework_version, macos_version)
            return framework_version
          end
        end

        nil
      rescue StandardError => e
        Fontist.ui.error("Error determining framework for macOS #{macos_version}: #{e.message}")
        nil
      end
    end
  end
end
