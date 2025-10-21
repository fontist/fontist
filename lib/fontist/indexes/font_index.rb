require_relative "default_family_font_index"
require_relative "preferred_family_font_index"

module Fontist
  module Indexes
    class FontIndex
      def self.from_file
        if Fontist.preferred_family?
          PreferredFamilyFontIndex.from_file
        else
          DefaultFamilyFontIndex.from_file
        end
      end
    end
  end
end
