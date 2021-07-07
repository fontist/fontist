require_relative "default_family_font_index"
require_relative "preferred_family_font_index"

module Fontist
  module Indexes
    class FontIndex
      def self.from_yaml
        if Fontist.preferred_family?
          PreferredFamilyFontIndex.from_yaml
        else
          DefaultFamilyFontIndex.from_yaml
        end
      end
    end
  end
end
