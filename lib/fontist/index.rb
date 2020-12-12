module Fontist
  class Index
    include Singleton

    def self.load_all
      instance.load_all
    end

    def self.load_formulas(font, style = nil)
      instance.load_formulas(font, style)
    end

    def initialize
      @index = load_index
    end

    def load_all
      Formulas.register_formulas
      Registry.formulas
    end

    def load_formulas(font, style)
      paths(font, style).map do |path|
        load_formula(path)
      end
    end

    private

    def load_index
      index = YAML.load_file(Fontist.formula_index_path)
      index.map do |font, styles|
        [font.downcase, downcase_keys(styles)]
      end.to_h
    end

    def downcase_keys(items)
      items.map do |key, value|
        [key.downcase, value]
      end.to_h
    end

    def paths(font, style)
      styles = @index[font.downcase]
      return [] unless styles

      paths = if style
                styles[style.downcase] || []
              else
                styles.values.flatten.uniq
              end

      paths.map do |file|
        Fontist.formulas_path.join(file).to_s
      end
    end

    def load_formula(path)
      klass = Formulas.create_formula_class(path)
      if klass
        Registry.register(klass)
        Registry.fetch(klass)
      else
        name = YAML.load_file(path)["name"]
        class_name = Formulas.name_to_classname(name)
        klass = Formulas.const_get(class_name)
        Registry.fetch(klass) || Registry.register(klass) && Registry.fetch(klass)
      end
    end
  end
end
