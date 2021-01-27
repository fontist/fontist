require_relative "indexes/font_index"
require_relative "indexes/filename_index"

module Fontist
  class Index
    def self.rebuild
      Fontist::Indexes::FontIndex.rebuild
      Fontist::Indexes::FilenameIndex.rebuild
    end
  end
end
