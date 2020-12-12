module Fontist
  class FormulaPaths
    attr_reader :font_paths

    def initialize(font_paths)
      @font_paths = font_paths
    end

    def find(font, style = nil)
      styles = find_styles_by_formulas(font, style)
      return if styles.empty?

      fonts = styles.uniq { |s| s["font"] }.flat_map do |s|
        paths = search_font_paths(s["font"])
        paths.map do |path|
          { full_name: s["full_name"],
            path: path }
        end
      end

      fonts.empty? ? nil : fonts
    end

    private

    def find_styles_by_formulas(font, style)
      if style
        Formula.find_styles(font, style)
      else
        fonts = Formula.find_fonts(font)
        return [] unless fonts

        fonts.flat_map(&:styles)
      end
    end

    def search_font_paths(filename)
      font_paths.select do |path|
        File.basename(path) == filename
      end
    end
  end
end
