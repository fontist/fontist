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

      def self.lookup_index
        if Fontist.preferred_family?
          PreferredFamilyFontIndex.lookup_index
        else
          DefaultFamilyFontIndex.lookup_index
        end
      end
    end
  end
end
