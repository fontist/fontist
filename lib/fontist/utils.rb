require_relative "utils/system"
require_relative "utils/file_magic"
require_relative "utils/locking"
require_relative "utils/downloader"
require_relative "utils/cache"
require_relative "utils/ui"

module Fontist
  module Utils
    # Converts a glob pattern to case-insensitive by replacing each
    # alphabetic character with a character class [aA]
    #
    # This is needed because File::FNM_CASEFOLD is ignored on case-sensitive
    # filesystems (Linux) as of Ruby 3.1+
    #
    # @param pattern [String] Original glob pattern (e.g., "*.ttf")
    # @return [String] Case-insensitive pattern (e.g., "*.[tT][tT][fF]")
    #
    # @example
    #   case_insensitive_glob("*.ttf")
    #   # => "*.[tT][tT][fF]"
    #
    #   case_insensitive_glob("*.{ttf,otf}")
    #   # => "*.[tT][tT][fF]" (note: doesn't handle braces, use multiple calls)
    def self.case_insensitive_glob(pattern)
      result = String.new
      pattern.each_char do |char|
        if char.downcase != char.upcase
          # Alphabetic character - create character class
          result << "[#{char.downcase}#{char.upcase}]"
        else
          # Non-alphabetic (numbers, punctuation) - keep as-is
          result << char
        end
      end
      result
    end

    # Returns array of case-insensitive glob patterns for font file extensions
    #
    # Generates patterns that match font files regardless of extension case
    # (e.g., .ttf, .TTF, .TtF all match)
    #
    # @param prefix [String] Path prefix (e.g., "/fonts/**")
    # @return [Array<String>] Array of patterns for each font extension
    #
    # @example
    #   font_file_patterns("/fonts/**")
    #   # => [
    #   #   "/fonts/**/*.[tT][tT][fF]",
    #   #   "/fonts/**/*.[oO][tT][fF]",
    #   #   "/fonts/**/*.[tT][tT][cC]",
    #   #   "/fonts/**/*.[oO][tT][cC]"
    #   # ]
    def self.font_file_patterns(prefix)
      %w[ttf otf ttc otc].map do |ext|
        File.join(prefix, "*#{case_insensitive_glob(".#{ext}")}")
      end
    end
  end
end
