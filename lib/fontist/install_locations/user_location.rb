require_relative "base_location"

module Fontist
  module InstallLocations
    # User font directory location
    #
    # This location represents the user-specific font directory, with
    # platform-specific base paths:
    #
    # macOS:   ~/Library/Fonts/fontist/
    # Linux:   ~/.local/share/fonts/fontist/
    # Windows: %LOCALAPPDATA%/Microsoft/Windows/Fonts/fontist/
    #
    # ## Managed vs Non-Managed
    #
    # This location is **managed** when:
    # - Using default path with /fontist subdirectory (default behavior)
    #
    # This location is **non-managed** when:
    # - User sets FONTIST_USER_FONTS_PATH to system root (e.g., ~/Library/Fonts)
    # - In non-managed mode, fonts are added with unique names to avoid conflicts
    #
    # ## Customization
    #
    # Set via environment variable:
    #   export FONTIST_USER_FONTS_PATH=~/Library/Fonts/fontist
    #
    # Or via config:
    #   fontist config set user_fonts_path ~/Library/Fonts/fontist
    class UserLocation < BaseLocation
      # Returns location type identifier
      # @return [Symbol] :user
      def location_type
        :user
      end

      # Returns base installation path
      #
      # Priority:
      # 1. Custom path from Config.user_fonts_path (if set)
      # 2. Platform default + /fontist subdirectory
      #
      # @return [Pathname] User font installation directory
      def base_path
        # Check for custom path from config/ENV
        custom_path = Fontist::Config.user_fonts_path
        return Pathname.new(File.expand_path(custom_path)) if custom_path

        # Default: platform-specific path + /fontist subdirectory
        default_user_path.join("fontist")
      end

      protected

      # Returns the UserIndex instance
      #
      # This index tracks all fonts installed in the user location
      #
      # @return [Indexes::UserIndex] Singleton index instance
      def index
        @index ||= Fontist::Indexes::UserIndex.instance
      end

      # Determines if this location is managed by Fontist
      #
      # User location is managed if:
      # - No custom path set (uses default /fontist subdirectory), OR
      # - Custom path ends with '/fontist' subdirectory
      #
      # User location is non-managed if:
      # - Custom path points to system root directory (e.g., ~/Library/Fonts)
      #
      # @return [Boolean] true if Fontist manages this location
      def managed_location?
        # If no custom path, we're using the default managed subdirectory
        return true unless Fontist::Config.user_fonts_path

        # If custom path ends with /fontist, it's managed
        uses_fontist_subdirectory?
      end

      private

      # Returns platform-specific default user font directory
      #
      # @return [Pathname] Base user font directory (without /fontist)
      def default_user_path
        base = case Fontist::Utils::System.user_os
               when :macos
                 File.expand_path("~/Library/Fonts")
               when :linux
                 File.expand_path("~/.local/share/fonts")
               when :windows
                 appdata = ENV["LOCALAPPDATA"] || File.expand_path("~/AppData/Local")
                 File.join(appdata, "Microsoft/Windows/Fonts")
               else
                 raise Fontist::Errors::GeneralError,
                       "Unsupported platform for user font installation: #{Fontist::Utils::System.user_os}"
               end

        Pathname.new(base)
      end

      # Checks if the base path uses fontist subdirectory
      #
      # @return [Boolean] true if path ends with /fontist
      def uses_fontist_subdirectory?
        base_path.to_s.end_with?("/fontist") || base_path.to_s.end_with?("\\fontist")
      end
    end
  end
end