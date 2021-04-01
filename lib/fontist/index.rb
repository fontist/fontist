require_relative "indexes/font_index"
require_relative "indexes/filename_index"

module Fontist
  class Index
    def self.rebuild
      Fontist::Indexes::FontIndex.rebuild
      Fontist::Indexes::FilenameIndex.rebuild
    end

    def self.reset_cache
      Fontist::Indexes::FontIndex.reset_cache
      Fontist::Indexes::FilenameIndex.reset_cache
    end
  end
end
