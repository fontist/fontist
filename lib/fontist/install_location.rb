require "pathname"
require_relative "install_locations/base_location"
require_relative "install_locations/fontist_location"
require_relative "install_locations/user_location"
require_relative "install_locations/system_location"

module Fontist
  # Factory for creating font installation location objects
  #
  # Provides a unified interface for creating location-specific installation
  # handlers. Each location type (fontist, user, system) has its own class
  # that manages font installation, index updates, and duplicate prevention.
  #
  # ## Location Types
  #
  # - **fontist**: ~/.fontist/fonts/{formula-key}/ (default, isolated, safe)
  # - **user**: Platform-specific user font directory with 'fontist' subdirectory
  # - **system**: Platform-specific system font directory with 'fontist' subdirectory
  #
  # ## Usage
  #
  #   # Create a specific location
  #   location = InstallLocation.create(formula, location_type: :user)
  #   location.install_font(source_path, "Roboto-Regular.ttf")
  #
  #   # Get all possible locations for a formula
  #   locations = InstallLocation.all_locations(formula)
  #   locations.each { |loc| puts loc.base_path }
  #
  # ## Platform-Specific Paths
  #
  # ### macOS
  # - user: ~/Library/Fonts/fontist/
  # - system (regular): /Library/Fonts/fontist/
  # - system (supplementary): /System/Library/Assets*/com_apple_MobileAsset_Font*/{asset}.asset/AssetData/
  #
  # ### Linux
  # - user: ~/.local/share/fonts/fontist/
  # - system: /usr/local/share/fonts/fontist/
  #
  # ### Windows
  # - user: %LOCALAPPDATA%\Microsoft\Windows\Fonts\fontist\
  # - system: %windir%\Fonts\fontist\
  #
  # ## Customization
  #
  # Override paths via environment variables or config:
  # - FONTIST_USER_FONTS_PATH - Custom user font path
  # - FONTIST_SYSTEM_FONTS_PATH - Custom system font path
  #
  # Or use config commands:
  #   fontist config set user_fonts_path /custom/path
  #   fontist config set system_fonts_path /custom/path
  class InstallLocation
    # Creates a location instance for the specified type
    #
    # @param formula [Formula] Formula object for the font
    # @param location_type [Symbol, String, nil] Location type (:fontist, :user, :system)
    #   If nil, uses default from Config.fonts_install_location
    # @return [BaseLocation] Location instance (FontistLocation, UserLocation, or SystemLocation)
    # @raise [ArgumentError] If location_type is invalid
    #
    # @example Create user location
    #   location = InstallLocation.create(formula, location_type: :user)
    #   location.install_font(source, "font.ttf")
    #
    # @example Use default location
    #   location = InstallLocation.create(formula)
    #   location.install_font(source, "font.ttf")
    def self.create(formula, location_type: nil)
      type = parse_location_type(location_type)

      case type
      when :fontist
        InstallLocations::FontistLocation.new(formula)
      when :user
        InstallLocations::UserLocation.new(formula)
      when :system
        InstallLocations::SystemLocation.new(formula)
      else
        raise ArgumentError, "Unknown location type: #{type}"
      end
    end

    # Returns all possible location instances for a formula
    #
    # Useful for:
    # - Searching across all locations for existing fonts
    # - Displaying all possible installation paths
    # - Uninstalling from all locations
    #
    # @param formula [Formula] Formula object for the font
    # @return [Array<BaseLocation>] Array of all location instances
    #
    # @example Find font across all locations
    #   InstallLocation.all_locations(formula).each do |location|
    #     fonts = location.find_fonts("Roboto")
    #     puts "#{location.location_type}: #{fonts}" if fonts
    #   end
    def self.all_locations(formula)
      [
        InstallLocations::FontistLocation.new(formula),
        InstallLocations::UserLocation.new(formula),
        InstallLocations::SystemLocation.new(formula),
      ]
    end

    private_class_method

    # Parses and validates location type
    #
    # @param value [Symbol, String, nil] Location type to parse
    # @return [Symbol] Normalized location type (:fontist, :user, :system)
    def self.parse_location_type(value)
      # Default to configured location if no value provided
      return Config.fonts_install_location if value.nil?

      # Normalize string input
      case value.to_s.downcase.tr("_", "-")
      when "fontist", "fontist-library"
        :fontist
      when "user"
        :user
      when "system"
        :system
      else
        # Invalid input - show error and fall back to default
        Fontist.ui.error(<<~ERROR.strip)
          Invalid install location: '#{value}'

          Valid options: fontist, user, system

          Using default location: fontist
        ERROR
        :fontist
      end
    end
  end
end