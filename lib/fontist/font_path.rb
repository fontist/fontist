require "fontist/indexes/filename_index"

module Fontist
  class FontPath
    def initialize(path)
      @path = path
    end

    def to_s
      [].tap do |s|
        s << "-"
        s << @path
        s << "(from #{formulas.join(' or ')} formula)" if formulas.any?
      end.join(" ")
    end

    def formulas
      @formulas ||= if fontist_font?
                      Indexes::FilenameIndex.from_yaml.load_index_formulas(File.basename(@path)).map(&:name)
                    else
                      []
                    end
    end

    def fontist_font?
      @path.start_with?(Fontist.fonts_path.to_s)
    end
  end
end
