require "pathname"
require "fileutils"

module Fontist
  module InstallLocations
    # Abstract base class for font installation locations
    #
    # This class provides the foundation for all installation location types,
    # implementing the core logic for:
    # - Managed vs non-managed location detection
    # - Font installation with duplicate prevention
    # - Unique filename generation for non-managed locations
    # - Educational warning messages
    # - Index management integration
    #
    # ## Managed vs Non-Managed Locations
    #
    # **Fontist-Managed Locations** (safe to replace fonts):
    # - Fontist library: ~/.fontist/fonts/{formula-key}/
    # - User default: ~/Library/Fonts/fontist/
    # - System default: /Library/Fonts/fontist/
    #
    # **Non-Managed Locations** (never replace existing fonts):
    # - Custom user root: ~/Library/Fonts/ (when FONTIST_USER_FONTS_PATH=~/Library/Fonts)
    # - Custom system root: /Library/Fonts/ (when FONTIST_SYSTEM_FONTS_PATH=/Library/Fonts)
    #
    # ## Subclass Requirements
    #
    # Subclasses must implement:
    # - base_path: Returns Pathname for installation directory
    # - location_type: Returns Symbol (:fontist, :user, :system)
    # - index: Returns index instance for this location
    #
    class BaseLocation
      attr_reader :formula

      def initialize(formula)
        @formula = formula
      end

      # Abstract methods that must be implemented by subclasses

      # Returns the base installation path for this location
      # @return [Pathname] Base installation directory
      def base_path
        raise NotImplementedError, "#{self.class} must implement #base_path"
      end

      # Returns the location type identifier
      # @return [Symbol] :fontist, :user, or :system
      def location_type
        raise NotImplementedError, "#{self.class} must implement #location_type"
      end

      # Shared interface methods

      # Returns full path for a font file
      # @param filename [String] The font filename
      # @return [Pathname] Full path where font should be installed
      def font_path(filename)
        base_path.join(filename)
      end

      # Installs a font file to this location
      #
      # Handles managed vs non-managed logic:
      # - Managed locations: Replace existing font if present
      # - Non-managed locations: Generate unique name to avoid conflicts
      #
      # @param source_path [String] Path to source font file
      # @param target_filename [String] Desired filename for font
      # @return [String, nil] Installed path or nil if skipped
      def install_font(source_path, target_filename)
        target = font_path(target_filename)

        # Check if font already exists at this location
        if font_exists?(target_filename)
          if managed_location?
            # Safe to replace in managed locations
            replace_font(source_path, target)
          else
            # Non-managed: use unique name to avoid overwriting user/system fonts
            unique_filename = generate_unique_filename(target_filename)
            install_with_warning(source_path, unique_filename, original_path: target)
          end
        else
          # New installation - simple case
          simple_install(source_path, target)
        end
      end

      # Uninstalls a font file from this location
      #
      # @param filename [String] Font filename to remove
      # @return [String, nil] Deleted path or nil if not found
      def uninstall_font(filename)
        target = font_path(filename)
        return nil unless File.exist?(target)

        File.delete(target)

        # Update this location's index
        index.remove_font(target.to_s)

        target.to_s
      end

      # Checks if a font exists at this location
      #
      # @param filename [String] Font filename to check
      # @return [Boolean] true if font exists
      def font_exists?(filename)
        path = font_path(filename).to_s
        index.font_exists?(path)
      end

      # Finds fonts by name and optional style at this location
      #
      # @param font_name [String] Font family name
      # @param style [String, nil] Optional style (e.g., "Regular", "Bold")
      # @return [Array<SystemIndexFont>, nil] Found fonts or nil
      def find_fonts(font_name, style = nil)
        index.find(font_name, style)
      end

      # Checks if this location requires elevated permissions
      #
      # @return [Boolean] true if sudo/admin rights needed
      def requires_elevated_permissions?
        false
      end

      # Returns warning message for installations requiring permissions
      #
      # @return [String, nil] Warning message or nil
      def permission_warning
        nil
      end

      protected

      # Returns the index instance for this location
      # Must be implemented by subclasses
      #
      # @return [Object] Index instance (FontistIndex, UserIndex, or SystemIndex)
      def index
        raise NotImplementedError, "#{self.class} must implement #index"
      end

      # Determines if this location is managed by Fontist
      #
      # Managed locations are safe to replace fonts in. This should be
      # overridden by subclasses based on their specific logic.
      #
      # @return [Boolean] true if Fontist manages this location
      def managed_location?
        true # Default: assume managed unless overridden
      end

      private

      # Replaces an existing font file (managed locations only)
      #
      # @param source [String] Source file path
      # @param target [Pathname] Target file path
      # @return [String] Installed path
      def replace_font(source, target)
        FileUtils.mkdir_p(target.dirname)
        FileUtils.cp(source, target)

        # Update index
        index.add_font(target.to_s)

        Fontist.ui.say("Replaced: #{target}") unless location_type == :fontist

        target.to_s
      end

      # Performs a simple installation (no existing font)
      #
      # @param source [String] Source file path
      # @param target [Pathname] Target file path
      # @return [String] Installed path
      def simple_install(source, target)
        FileUtils.mkdir_p(target.dirname)
        FileUtils.cp(source, target)

        # Update index
        index.add_font(target.to_s)

        Fontist.ui.say("Installed: #{target}") unless location_type == :fontist

        target.to_s
      end

      # Generates a unique filename for non-managed locations
      #
      # Strategy:
      # 1. Try: Roboto-Regular-fontist.ttf
      # 2. Try: Roboto-Regular-fontist-2.ttf
      # 3. Try: Roboto-Regular-fontist-3.ttf, etc.
      #
      # @param filename [String] Original filename
      # @return [String] Unique filename that doesn't exist
      def generate_unique_filename(filename)
        base = File.basename(filename, File.extname(filename))
        ext = File.extname(filename)

        # Try -fontist suffix first
        candidate = "#{base}-fontist#{ext}"
        return candidate unless File.exist?(font_path(candidate))

        # Try numbered suffixes
        counter = 2
        loop do
          candidate = "#{base}-fontist-#{counter}#{ext}"
          return candidate unless File.exist?(font_path(candidate))
          counter += 1
        end
      end

      # Installs font with unique name and shows educational warning
      #
      # @param source [String] Source file path
      # @param unique_filename [String] Unique filename to use
      # @param original_path [Pathname] Path where font already exists
      # @return [String] Installed path
      def install_with_warning(source, unique_filename, original_path:)
        target = font_path(unique_filename)

        FileUtils.mkdir_p(target.dirname)
        FileUtils.cp(source, target)

        # Update index
        index.add_font(target.to_s)

        # Show educational warning
        show_duplicate_warning(original_path, target)

        target.to_s
      end

      # Displays educational warning about duplicate installation
      #
      # @param original_path [Pathname] Original font path
      # @param new_path [Pathname] New fontist-managed path
      def show_duplicate_warning(original_path, new_path)
        Fontist.ui.say(<<~WARNING)

          ⚠️  DUPLICATE FONT INSTALLED IN NON-FONTIST-MANAGED LOCATION

          Font already exists at:
            #{original_path} (system/user font, not managed by Fontist)

          Fontist installed a duplicate with unique name at:
            #{new_path} (new Fontist install)

          Why duplicate? This location is not managed by Fontist. To avoid breaking
          existing system/user fonts, Fontist adds fonts with unique names instead of
          replacing existing files.

          Fontist-managed locations (safe to replace):
            - ~/.fontist/fonts/{formula}/           (Fontist library)
            - #{platform_user_managed_example}      (User managed subdirectory)
            - #{platform_system_managed_example}    (System managed subdirectory)

          You can manually delete the old font file if you want to use only the
          Fontist-managed version.
        WARNING
      end

      # Returns platform-specific example of user managed path
      # @return [String] Example path
      def platform_user_managed_example
        case Fontist::Utils::System.user_os
        when :macos
          "~/Library/Fonts/fontist/"
        when :linux
          "~/.local/share/fonts/fontist/"
        when :windows
          "%LOCALAPPDATA%/Microsoft/Windows/Fonts/fontist/"
        else
          "/path/to/user/fonts/fontist/"
        end
      end

      # Returns platform-specific example of system managed path
      # @return [String] Example path
      def platform_system_managed_example
        case Fontist::Utils::System.user_os
        when :macos
          "/Library/Fonts/fontist/"
        when :linux
          "/usr/local/share/fonts/fontist/"
        when :windows
          "%windir%/Fonts/fontist/"
        else
          "/path/to/system/fonts/fontist/"
        end
      end
    end
  end
end