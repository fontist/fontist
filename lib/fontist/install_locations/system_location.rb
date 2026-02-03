require_relative "base_location"

module Fontist
  module InstallLocations
    # System font directory location
    #
    # This location represents the system-wide font directory, with
    # platform-specific base paths:
    #
    # macOS (regular):     /Library/Fonts/fontist/
    # macOS (supplementary): /System/Library/Assets*/com_apple_MobileAsset_Font*/{asset}.asset/AssetData/
    # Linux:               /usr/local/share/fonts/fontist/
    # Windows:             %windir%/Fonts/fontist/
    #
    # ## Managed vs Non-Managed
    #
    # This location is **managed** when:
    # - Using default path with /fontist subdirectory (default behavior)
    # - Installing macOS supplementary fonts (always OS-managed)
    #
    # This location is **non-managed** when:
    # - User sets FONTIST_SYSTEM_FONTS_PATH to system root (e.g., /Library/Fonts)
    # - In non-managed mode, fonts are added with unique names to avoid conflicts
    #
    # ## Permissions
    #
    # This location **always requires elevated permissions** (sudo/admin rights)
    # Shows warning before installation attempts
    #
    # ## Customization
    #
    # Set via environment variable:
    #   export FONTIST_SYSTEM_FONTS_PATH=/Library/Fonts/fontist
    #
    # Or via config:
    #   fontist config set system_fonts_path /Library/Fonts/fontist
    class SystemLocation < BaseLocation
      # Returns location type identifier
      # @return [Symbol] :system
      def location_type
        :system
      end

      # Returns base installation path
      #
      # Priority:
      # 1. Custom path from Config.system_fonts_path (if set)
      # 2. Platform default + /fontist subdirectory
      #    - Exception: macOS supplementary fonts use special OS-managed paths
      #
      # @return [Pathname] System font installation directory
      def base_path
        # Check for custom path from config/ENV
        custom_path = Fontist::Config.system_fonts_path
        return Pathname.new(File.expand_path(custom_path)) if custom_path

        # Platform-specific default paths
        case Fontist::Utils::System.user_os
        when :macos
          macos_system_path
        when :linux
          Pathname.new("/usr/local/share/fonts").join("fontist")
        when :windows
          windows_dir = ENV["windir"] || ENV["SystemRoot"] || "C:/Windows"
          Pathname.new(windows_dir).join("Fonts/fontist")
        else
          raise Fontist::Errors::GeneralError,
                "Unsupported platform for system font installation: #{Fontist::Utils::System.user_os}"
        end
      end

      # System installations always require elevated permissions
      #
      # @return [Boolean] Always true
      def requires_elevated_permissions?
        true
      end

      # Returns warning message about elevated permissions
      #
      # @return [String] Warning message
      def permission_warning
        <<~WARNING
          ⚠️  WARNING: Installing to system font directory

          This requires root/administrator permissions and may affect your system.

          Installation will fail if you don't have sufficient permissions.

          Recommended alternatives:
          - Use default (fontist): Safe, isolated, no permissions needed
          - Use --location=user: Install to your user font directory

          Continue with system installation? (Ctrl+C to cancel)
        WARNING
      end

      protected

      # Returns the SystemIndex instance
      #
      # This index tracks all fonts installed in system locations
      #
      # @return [Indexes::SystemIndex] Singleton index instance
      def index
        @index ||= Fontist::Indexes::SystemIndex.instance
      end

      # Determines if this location is managed by Fontist
      #
      # System location is managed if:
      # - Installing macOS supplementary font (always OS-managed), OR
      # - No custom path set (uses default /fontist subdirectory), OR
      # - Custom path ends with '/fontist' subdirectory
      #
      # System location is non-managed if:
      # - Custom path points to system root directory (e.g., /Library/Fonts)
      #
      # @return [Boolean] true if Fontist manages this location
      def managed_location?
        # macOS supplementary fonts are always OS-managed
        return true if formula.macos_import?

        # If no custom path, we're using the default managed subdirectory
        return true unless Fontist::Config.system_fonts_path

        # If custom path ends with /fontist, it's managed
        uses_fontist_subdirectory?
      end

      private

      # Returns macOS-specific system path (varies by font type)
      #
      # Regular fonts:       /Library/Fonts/fontist/
      # Supplementary fonts: /System/Library/Assets*/com_apple_MobileAsset_Font*/{asset}.asset/AssetData/
      #
      # @return [Pathname] macOS system font directory
      def macos_system_path
        # macOS supplementary fonts (platform-tagged formulas) use special OS-managed paths
        # These paths cannot use subdirectories as they are managed by the OS
        if formula.macos_import?
          macos_supplementary_path
        else
          # Regular fonts go to /Library/Fonts/fontist
          Pathname.new("/Library/Fonts").join("fontist")
        end
      end

      # Returns macOS supplementary font path with asset structure
      #
      # Structure: /System/Library/Assets*/com_apple_MobileAsset_Font<N>/{asset_id}.asset/AssetData/
      #
      # @return [Pathname] macOS supplementary font path
      def macos_supplementary_path
        framework = framework_version
        unless framework
          raise Fontist::Errors::GeneralError,
                "Cannot determine framework version for macOS supplementary font"
        end

        base = Fontist::MacosFrameworkMetadata.system_install_path(framework)
        unless base
          raise Fontist::Errors::GeneralError,
                "No system path available for framework #{framework}"
        end

        asset_id = formula.import_source.asset_id
        unless asset_id
          raise Fontist::Errors::GeneralError,
                "Asset ID required for macOS supplementary font installation"
        end

        Pathname.new(base)
          .join("#{asset_id}.asset")
          .join("AssetData")
      end

      # Determines framework version from formula or current system
      #
      # @return [Integer, nil] Framework version number
      def framework_version
        if formula.macos_import?
          formula.import_source.framework_version
        else
          Fontist::Utils::System.catalog_version_for_macos
        end
      end

      # Checks if the base path uses fontist subdirectory
      #
      # @return [Boolean] true if path ends with /fontist
      def uses_fontist_subdirectory?
        base_path.to_s.end_with?("/fontist", "\\fontist")
      end
    end
  end
end
