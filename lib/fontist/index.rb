require_relative "indexes/font_index"
require_relative "indexes/filename_index"

module Fontist
  class Index
    def self.rebuild
      Fontist::Indexes::DefaultFamilyFontIndex.rebuild
      Fontist::Indexes::PreferredFamilyFontIndex.rebuild
      Fontist::Indexes::FilenameIndex.rebuild

      reset_cache
    end

    def self.reset_cache
      Fontist::Indexes::DefaultFamilyFontIndex.reset_cache
      Fontist::Indexes::PreferredFamilyFontIndex.reset_cache
      Fontist::Indexes::FilenameIndex.reset_cache
    end
  end
end
