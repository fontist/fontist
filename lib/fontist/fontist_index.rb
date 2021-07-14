module Fontist
  class FontistIndex < SystemIndex
    def self.font_paths
      SystemFont.fontist_font_paths
    end

    private

    def path
      Fontist.fontist_index_path
    end
  end
end
