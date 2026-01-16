require_relative "utils/system"
require_relative "utils/file_magic"
require_relative "utils/locking"
require_relative "utils/downloader"
require_relative "utils/cache"
require_relative "utils/ui"
require_relative "utils/file_ops"

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
      result = +""
      pattern.each_char do |char|
        result << if char.downcase == char.upcase
                    # Non-alphabetic (numbers, punctuation) - keep as-is
                    char
                  else
                    # Alphabetic character - create character class
                    "[#{char.downcase}#{char.upcase}]"
                  end
      end
      result
    end

    # Returns array of case-insensitive glob patterns for font file extensions
    #
    # Generates patterns that match font files regardless of extension case.
    # On case-insensitive filesystems (Windows, macOS), uses simple lowercase patterns.
    # On case-sensitive filesystems (Linux), uses character class patterns like [tT][tT][fF].
    #
    # @param prefix [String] Path prefix (e.g., "/fonts/**")
    # @return [Array<String>] Array of patterns for each font extension
    #
    # @example Linux (case-sensitive)
    #   font_file_patterns("/fonts/**")
    #   # => [
    #   #   "/fonts/**/*.[tT][tT][fF]",
    #   #   "/fonts/**/*.[oO][tT][fF]",
    #   #   "/fonts/**/*.[tT][tT][cC]",
    #   #   "/fonts/**/*.[o O][tT][cC]"
    #   # ]
    #
    # @example Windows/macOS (case-insensitive)
    #   font_file_patterns("/fonts/**")
    #   # => [
    #   #   "/fonts/**/*.ttf",
    #   #   "/fonts/**/*.otf",
    #   #   "/fonts/**/*.ttc",
    #   #   "/fonts/**/*.otc"
    #   # ]
    def self.font_file_patterns(prefix)
      extensions = %w[ttf otf ttc otc]

      # On case-insensitive filesystems (Windows, macOS), use simple patterns
      # On case-sensitive filesystems (Linux), use character class patterns
      if %i[windows macosx].include?(Fontist::Utils::System.user_os)
        # Case-insensitive filesystem - simple patterns work fine
        extensions.map { |ext| File.join(prefix, "*.#{ext}") }
      else
        # Case-sensitive filesystem (Linux) - use character classes
        extensions.map do |ext|
          File.join(prefix, "*#{case_insensitive_glob(".#{ext}")}")
        end
      end
    end
  end
end
