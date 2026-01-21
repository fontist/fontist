# frozen_string_literal: true

module Fontist
  module Test
    # Platform-specific test font configuration
    #
    # This module provides platform-appropriate fonts for testing to ensure
    # tests work consistently across Windows, macOS, and Linux.
    #
    # Key principles:
    # 1. Use fonts that are NOT pre-installed on the test platform for installation tests
    # 2. Use fonts that ARE pre-installed on the test platform for detection tests
    # 3. Keep tests MECE (Mutually Exclusive, Collectively Exhaustive)
    #
    # System font data is loaded from fixtures captured from real systems.
    # To capture new system fonts, run: rake system_fonts:capture
    module PlatformFonts
      # Load system fonts from fixtures (captured from real systems)
      FIXTURES_DIR = File.join(Fontist.root_path, "spec", "fixtures",
                               "system_fonts")

      class << self
        # Load system fonts fixtures for all platforms
        def load_system_fonts_fixtures!
          return if @fixtures_loaded

          @system_fonts_fixtures ||= {}

          %i[windows macos linux].each do |platform|
            fixture_file = File.join(FIXTURES_DIR,
                                     "#{platform}_system_fonts.yml")
            if File.exist?(fixture_file)
              data = YAML.load_file(fixture_file)
              @system_fonts_fixtures[platform] =
                Set.new(data["font_families"] || [])
            else
              @system_fonts_fixtures[platform] = Set.new
            end
          end

          @fixtures_loaded = true
        end

        # Get system fonts for a platform (from fixtures or fallback to hardcoded)
        def system_fonts_for_platform(platform)
          load_system_fonts_fixtures! unless @fixtures_loaded

          if @system_fonts_fixtures[platform]&.any?
            @system_fonts_fixtures[platform]
          else
            # Fallback to hardcoded lists if fixtures not available
            case platform
            when :windows
              Set.new(HARDCODED_WINDOWS_SYSTEM_FONTS)
            when :macos
              Set.new(HARDCODED_MACOS_SYSTEM_FONTS)
            else
              Set.new
            end
          end
        end

        # Check if a font is a system font on the given platform
        def system_font_on_platform?(font_name, platform)
          system_fonts_for_platform(platform).include?(font_name)
        end

        # Returns a font that can be INSTALLED on the current platform
        # (i.e., a font that is NOT already pre-installed)
        #
        # @return [String] Font name for installation tests
        def installable_test_font
          INSTALLABLE_TEST_FONTS[current_platform]
        end

        # Returns the formula file name for the installable test font
        #
        # @return [String] Formula file name (e.g., "lato.yml")
        def installable_test_formula
          INSTALLABLE_TEST_FORMULAS[current_platform]
        end

        # Returns the font file name for the installable test font
        #
        # @return [String] Font file name (e.g., "Lato-Regular.ttf")
        def installable_test_font_file
          INSTALLABLE_TEST_FONT_FILES[current_platform]
        end

        # Returns the full name for the installable test font
        #
        # @return [String] Full font name (e.g., "Lato")
        def installable_test_font_full_name
          INSTALLABLE_TEST_FONT_FULL_NAMES[current_platform]
        end

        # Returns a second font that can be INSTALLED on the current platform
        # For tests that need multiple fonts
        #
        # @return [String] Second font name for installation tests
        def second_installable_test_font
          SECOND_INSTALLABLE_TEST_FONTS[current_platform]
        end

        # Returns the formula file name for the second installable test font
        #
        # @return [String] Formula file name (e.g., "courier.yml")
        def second_installable_test_formula
          SECOND_INSTALLABLE_TEST_FORMULAS[current_platform]
        end

        # Returns the font file name for the second installable test font
        #
        # @return [String] Font file name (e.g., "courbd.ttf")
        def second_installable_test_font_file
          SECOND_INSTALLABLE_TEST_FONT_FILES[current_platform]
        end

        # Returns the full name for the second installable test font
        #
        # @return [String] Full font name (e.g., "Courier New Bold")
        def second_installable_test_font_full_name
          SECOND_INSTALLABLE_TEST_FONT_FULL_NAMES[current_platform]
        end

        # Returns a font that IS a system font on the current platform
        # Used for testing system font detection (not installation)
        #
        # @return [String, nil] Font name for detection tests, or nil if no system font available
        def system_test_font
          SYSTEM_TEST_FONTS[current_platform]
        end

        # Returns the path to the platform-appropriate test manifest
        #
        # @return [Pathname] Path to test manifest YAML
        def test_manifest_path
          manifest_name = case current_platform
                          when :windows then "test_manifest_windows.yml"
                          when :macos then "test_manifest_macos.yml"
                          when :linux then "test_manifest_linux.yml"
                          end

          Fontist.root_path.join("spec", "fixtures", manifest_name)
        end

        # Check if a font is a system font on the current platform
        #
        # @param font_name [String] The font name to check
        # @return [Boolean] True if the font is a system font on this platform
        def system_font?(font_name)
          system_font_on_platform?(font_name, current_platform)
        end

        # Check if tests should expect the font to already be installed
        # (because it's a system font on the current platform)
        #
        # @param font_name [String] The font name to check
        # @return [Boolean] True if the font should already exist on this platform
        def font_already_installed?(font_name)
          system_font?(font_name)
        end

        # Get all system fonts for the current platform
        #
        # @return [Set<String>] Set of system font names
        def current_platform_system_fonts
          system_fonts_for_platform(current_platform)
        end

        # Check if a font is safe to use for installation tests
        # (i.e., NOT a system font on the current platform)
        #
        # @param font_name [String] The font name to check
        # @return [Boolean] True if the font can be used for installation tests
        def safe_for_installation_test?(font_name)
          !system_font?(font_name)
        end

        private

        def current_platform
          Fontist::Utils::System.user_os
        end
      end

      # Hardcoded fallback lists (used when fixtures not available)
      # These should be kept in sync with actual system fonts
      HARDCODED_WINDOWS_SYSTEM_FONTS = %w[
        Arial
        Cambria
        Calibri
        Courier New
        Georgia
        Segoe UI
        Times New Roman
        Tahoma
        Trebuchet MS
        Verdana
      ].freeze

      HARDCODED_MACOS_SYSTEM_FONTS = %w[
        Helvetica
        Monaco
        Menlo
        SF Pro Display
        SF Pro Text
      ].freeze

      # Fonts available as fixtures that are NOT Windows system fonts
      # These can be used for installation tests on Windows
      INSTALLABLE_TEST_FONTS = {
        windows: "Andale Mono",
        macos: "Andale Mono",
        linux: "Andale Mono",
      }.freeze

      # Formula files for installable test fonts
      INSTALLABLE_TEST_FORMULAS = {
        windows: "andale.yml",
        macos: "andale.yml",
        linux: "andale.yml",
      }.freeze

      # Font file names for installable test fonts (Regular style)
      INSTALLABLE_TEST_FONT_FILES = {
        windows: "AndaleMo.TTF",
        macos: "AndaleMo.TTF",
        linux: "AndaleMo.TTF",
      }.freeze

      # Full names for installable test fonts (Regular style)
      INSTALLABLE_TEST_FONT_FULL_NAMES = {
        windows: "Andale Mono",
        macos: "Andale Mono",
        linux: "Andale Mono",
      }.freeze

      # Second set of installable test fonts for multi-font tests
      SECOND_INSTALLABLE_TEST_FONTS = {
        windows: "Courier New",
        macos: "Courier New",
        linux: "Courier New",
      }.freeze

      # Formula files for second installable test fonts
      SECOND_INSTALLABLE_TEST_FORMULAS = {
        windows: "courier.yml",
        macos: "courier.yml",
        linux: "courier.yml",
      }.freeze

      # Font file names for second installable test fonts (use Regular style)
      SECOND_INSTALLABLE_TEST_FONT_FILES = {
        windows: "courbd.ttf",
        macos: "courbd.ttf",
        linux: "courbd.ttf",
      }.freeze

      # Full names for second installable test fonts (use Regular style)
      SECOND_INSTALLABLE_TEST_FONT_FULL_NAMES = {
        windows: "Courier New Bold",
        macos: "Courier New Bold",
        linux: "Courier New Bold",
      }.freeze

      # Fonts available as fixtures that ARE system fonts
      # These can be used for detection tests (verify Fontist finds them)
      SYSTEM_TEST_FONTS = {
        windows: "Andale Mono",
        macos: "Helvetica",
        linux: nil, # Linux typically has no guaranteed system fonts
      }.freeze
    end
  end
end
