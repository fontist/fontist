module Fontist
  class FontistFont
    def initialize(font_name:)
      @font_name = font_name
    end

    def self.find(name)
      new(font_name: name).find
    end

    def find
      styles = FormulaPaths.new(font_paths).find(@font_name)
      return unless styles

      styles.map { |x| x[:path] }
    end

    private

    def font_paths
      Dir.glob(Fontist.fonts_path.join("**"))
    end
  end
end
