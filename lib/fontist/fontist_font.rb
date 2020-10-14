module Fontist
  class FontistFont
    def initialize(font_name:)
      @font_name = font_name

      check_and_register_font_formulas
    end

    def self.find(name)
      new(font_name: name).find
    end

    def find
      return unless @font_name

      filenames = fonts_filenames
      return if filenames.empty?

      paths = font_paths.select do |path|
        filenames.any? { |f| File.basename(path).casecmp?(f) }
      end

      paths.empty? ? nil : paths
    end

    private

    def fonts_filenames
      fonts.map { |font| font.styles.map(&:font) }.flatten
    end

    def fonts
      by_key || by_name || []
    end

    def by_key
      _key, formula = formulas.detect do |key, _value|
        key.to_s.casecmp?(@font_name)
      end

      return unless formula

      formula.fonts
    end

    def by_name
      _key, formula = formulas.detect do |_key, value|
        value.fonts.map(&:name).map(&:downcase).include?(@font_name.downcase)
      end

      return unless formula

      formula.fonts.select do |font|
        font.name.casecmp?(@font_name)
      end
    end

    def formulas
      @formulas ||= Fontist::Registry.instance.formulas.to_h
    end

    def font_paths
      Dir.glob(Fontist.fonts_path.join("**"))
    end

    def check_and_register_font_formulas
      $check_and_register_font_formulas ||= Fontist::Formulas.register_formulas
    end
  end
end
