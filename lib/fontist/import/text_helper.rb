module Fontist
  module Import
    module TextHelper
      class << self
        def cleanup(text)
          return unless text

          text.gsub("\r\n", "\n")
            .gsub("\r", "\n")
            .strip
            .lines
            .map(&:rstrip)
            .drop_while(&:empty?)
            .join("\n")
        end

        def longest_common_prefix(strs)
          return if strs.empty?

          min, max = strs.minmax
          idx = min.size.times { |i| break i if min[i] != max[i] }
          prefix = min[0...idx].strip
          return if prefix.empty?

          prefix
        end
      end
    end
  end
end
