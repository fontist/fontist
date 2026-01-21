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
                      Indexes::FilenameIndex.from_file.load_index_formulas(File.basename(@path)).flat_map(&:name)
                    else
                      []
                    end
    end

    def fontist_font?
      # Normalize path separators to forward slashes for comparison
      normalized_path = @path.gsub("\\", "/")
      normalized_fonts_path = Fontist.fonts_path.to_s.gsub("\\", "/")

      # DEBUG: Log path comparison on Windows
      if ENV["DEBUG_FONT_PATH"]
        puts "DEBUG FontPath#fontist_font?:"
        puts "  @path: #{@path.inspect}"
        puts "  normalized_path: #{normalized_path.inspect}"
        puts "  Fontist.fonts_path.to_s: #{Fontist.fonts_path.to_s.inspect}"
        puts "  normalized_fonts_path: #{normalized_fonts_path.inspect}"
        puts "  Fontist::Utils::System.windows?: #{Fontist::Utils::System.windows?.inspect}"
      end

      # On Windows, use case-insensitive comparison; on Unix, case-sensitive
      result = if Fontist::Utils::System.windows?
        normalized_path.downcase.start_with?(normalized_fonts_path.downcase)
      else
        normalized_path.start_with?(normalized_fonts_path)
      end

      puts "  result: #{result.inspect}" if ENV["DEBUG_FONT_PATH"]
      result
    end
  end
end
