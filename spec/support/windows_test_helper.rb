# frozen_string_literal: true

# WindowsTestHelper provides Windows-specific test environment setup.
#
# This module handles platform-specific configuration for Windows tests,
# including temp directory configuration and console encoding.
#
# The helper is automatically loaded in spec_helper.rb and runs before
# the test suite when on Windows platform.
module WindowsTestHelper
  # Setup Windows-specific test environment
  #
  # Called from RSpec.configure before(:suite) when on Windows.
  # Configures temp directories and console encoding.
  #
  # @return [void]
  def self.setup
    return unless windows?

    configure_temp_directories
    configure_console_encoding
  end

  # Check if running on Windows platform
  #
  # @return [Boolean] true if Windows, false otherwise
  def self.windows?
    Fontist::Utils::System.user_os == :windows
  end

  # Configure temp directory for Windows
  #
  # Windows uses different temp directory locations than Unix.
  # Ensures TMPDIR is set to a Windows-appropriate location.
  #
  # @return [void]
  # @api private
  def self.configure_temp_directories
    # Set TMPDIR if not already set, using Windows-appropriate defaults
    ENV["TMPDIR"] ||= ENV["TEMP"] || ENV["TMP"] || "C:/Windows/Temp"

    # Ensure temp directory exists
    FileUtils.mkdir_p(ENV["TMPDIR"]) unless Dir.exist?(ENV["TMPDIR"])
  end

  # Configure console encoding for Windows
  #
  # Windows console uses different encoding (CP850, CP1252) than Unix.
  # This ensures proper character handling in test output.
  #
  # @return [void]
  # @api private
  def self.configure_console_encoding
    # Set default external encoding to UTF-8 for consistency
    if defined?(Encoding) && Encoding.default_external != Encoding::UTF_8
      Encoding.default_external = Encoding::UTF_8
    end
  end

  # Check if a test should be skipped on Windows
  #
  # Some tests may be Unix-specific and should be skipped on Windows.
  # This provides a consistent way to check.
  #
  # @return [Boolean] true if test should be skipped
  #
  # @example In a spec file:
  #   it "does something", skip: WindowsTestHelper.skip_on_windows? do
  #     # test code
  #   end
  def self.skip_on_windows?
    windows?
  end
end