# frozen_string_literal: true

# PathHelper provides cross-platform path normalization utilities for RSpec tests.
#
# Windows uses backslashes (\) and drive letters (C:), while Unix uses forward
# slashes (/). This module normalizes paths to Unix-style for consistent test
# assertions across all platforms.
#
# Usage:
#   RSpec.describe "Font paths" do
#     include PathHelper
#
#     it "returns correct path" do
#       # Instead of: expect(font_path).to eq("/Users/user/.fontist/fonts/courier.ttf")
#       # Use: expect_path(font_path, "/Users/user/.fontist/fonts/courier.ttf")
#     end
#   end
module PathHelper
  # Normalize a path for cross-platform test assertions
  #
  # Converts:
  #   - Backslashes to forward slashes (\ → /)
  #   - Removes drive letters (C: → empty)
  #   - Normalizes multiple slashes (// → /)
  #
  # @param path [String, Pathname] The path to normalize
  # @return [String] Normalized path in Unix format
  #
  # @example
  #   normalize_test_path("C:\\Users\\user\\.fontist\\fonts\\courier.ttf")
  #   # => "/Users/user/.fontist/fonts/courier.ttf"
  def normalize_test_path(path)
    path.to_s
        .tr('\\', '/')           # Windows backslashes to forward slashes
        .sub(/^[A-Z]:/, '')      # Remove drive letters (C:, D:, etc.)
        .gsub(/\/+/, '/')        # Normalize multiple slashes to single
  end

  # Cross-platform path expectation
  #
  # Normalizes both actual and expected paths before comparison.
  # This allows tests to use Unix-style paths in expectations while
  # working correctly on Windows.
  #
  # @param actual [String, Pathname] The actual path from production code
  # @param expected [String, Pathname] The expected path (Unix-style)
  #
  # @example
  #   expect_path(font.path, "/Users/user/.fontist/fonts/courier.ttf")
  def expect_path(actual, expected)
    expect(normalize_test_path(actual)).to eq(normalize_test_path(expected))
  end

  # Cross-platform path array expectation
  #
  # Normalizes all paths in both arrays before comparison.
  # Uses match_array for order-independent comparison.
  #
  # @param actual_array [Array<String>] Actual paths from production code
  # @param expected_array [Array<String>] Expected paths (Unix-style)
  #
  # @example
  #   expect_paths(font.all_paths, [
  #     "/Users/user/.fontist/fonts/courier.ttf",
  #     "/Users/user/.fontist/fonts/courier-bold.ttf"
  #   ])
  def expect_paths(actual_array, expected_array)
    actual_normalized = actual_array.map { |p| normalize_test_path(p) }
    expected_normalized = expected_array.map { |p| normalize_test_path(p) }
    expect(actual_normalized).to match_array(expected_normalized)
  end

  # Normalize a path within a hash structure
  #
  # Useful for normalizing paths in complex data structures like
  # formula metadata or manifest outputs.
  #
  # @param hash [Hash] The hash containing path values
  # @param key [Symbol, String] The key whose value should be normalized
  # @return [Hash] Hash with normalized path value
  #
  # @example
  #   normalize_hash_path(result, :path)
  def normalize_hash_path(hash, key)
    return hash unless hash[key]
    hash.merge(key => normalize_test_path(hash[key]))
  end
end