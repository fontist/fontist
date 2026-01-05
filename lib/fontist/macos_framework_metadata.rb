require "rubygems"

module Fontist
  # Loads and provides access to macOS font framework metadata
  #
  # This class centralizes framework-specific information that was previously
  # stored in individual formulas, enabling proper separation of concerns.
  class MacosFrameworkMetadata
    METADATA = {
      3 => {
        "min_macos_version" => "10.10",
        "max_macos_version" => "10.12",
        "parser_class" => "Fontist::Macos::Catalog::Font3Parser",
        "description" => "Font3 framework (macOS Yosemite, El Capitan, Sierra)"
      },
      4 => {
        "min_macos_version" => "10.12",
        "max_macos_version" => "10.13",
        "parser_class" => "Fontist::Macos::Catalog::Font4Parser",
        "description" => "Font4 framework (macOS Sierra, High Sierra)"
      },
      5 => {
        "min_macos_version" => "10.13",
        "max_macos_version" => "10.15",
        "parser_class" => "Fontist::Macos::Catalog::Font5Parser",
        "description" => "Font5 framework (macOS High Sierra, Mojave, Catalina)"
      },
      6 => {
        "min_macos_version" => "11.0",
        "max_macos_version" => "11.7",
        "parser_class" => "Fontist::Macos::Catalog::Font6Parser",
        "description" => "Font6 framework (macOS Big Sur)"
      },
      7 => {
        "min_macos_version" => "10.11",
        "max_macos_version" => "15.7",
        "parser_class" => "Fontist::Macos::Catalog::Font7Parser",
        "description" => "Font7 framework (macOS Monterey, Ventura, Sonoma)"
      },
      8 => {
        "min_macos_version" => "26.0",
        "max_macos_version" => nil,
        "parser_class" => "Fontist::Macos::Catalog::Font8Parser",
        "description" => "Font8 framework (macOS Sequoia+)"
      }
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
        metadata.dig(framework_version, "description") || "Unknown framework #{framework_version}"
      end
    end
  end
end