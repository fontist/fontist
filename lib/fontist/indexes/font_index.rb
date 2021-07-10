require_relative "default_family_font_index"
require_relative "preferred_family_font_index"

module Fontist
  module Indexes
    class FontIndex
      def self.from_yaml
        if Fontist.default_families?
          DefaultFamilyFontIndex.from_yaml
        else
          PreferredFamilyFontIndex.from_yaml
        end
      end

      def self.reset_cache
        DefaultFamilyFontIndex.reset_cache
        PreferredFamilyFontIndex.reset_cache
      end

      def self.rebuild
        DefaultFamilyFontIndex.rebuild
        PreferredFamilyFontIndex.rebuild
      end
    end
  end
end
