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
            .join("\n")
        end
      end
    end
  end
end
