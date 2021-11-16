require "fontist/style_version"

module Fontist
  class FormulaPicker
    def initialize(font_name, size_limit:, version:, smallest:, newest:)
      @font_name = font_name
      @size_limit = size_limit || Fontist.formula_size_limit_in_megabytes
      @version = version
      @smallest = smallest
      @newest = newest
    end

    def call(formulas)
      return [] if formulas.size.zero?
      return formulas if contain_different_styles?(formulas)
      return by_version(formulas) if version_is_passed?
      return newest(formulas) if newest_is_passed?
      return smallest(formulas) if smallest_is_passed?

      default_way(formulas)
    end

    private

    def version_is_passed?
      !@version.nil?
    end

    def by_version(formulas)
      formulas.each do |formula|
        fonts = formula.fonts_by_name(@font_name)
        fonts.each do |font|
          font.styles.each do |style|
            version = StyleVersion.new(style.version)
            return [formula] if version == passed_version
          end
        end
      end

      []
    end

    def passed_version
      @passed_version ||= StyleVersion.new(@version)
    end

    def newest_is_passed?
      @newest
    end

    def newest(formulas)
      newest_formulas = filter_by_max_version(formulas)
      smallest(newest_formulas)
    end

    def smallest_is_passed?
      @smallest
    end

    def smallest(formulas)
      [choose_smallest_formula(formulas)]
    end

    def default_way(formulas)
      size_limited_formulas = filter_by_size_limit(formulas)
      raise_size_limit_error if size_limited_formulas.empty?
      newest(size_limited_formulas)
    end

    def contain_different_styles?(formulas)
      styles_by_formula = formulas.map do |formula|
        fonts = formula.fonts_by_name(@font_name)
        styles = fonts.flat_map do |font|
          font.styles.map(&:type)
        end

        styles.uniq.sort
      end

      styles_by_formula.uniq.size > 1
    end

    def filter_by_size_limit(formulas)
      formulas.select do |formula|
        formula.file_size.nil? || formula.file_size < size_limit_in_bytes
      end
    end

    def size_limit_in_bytes
      @size_limit_in_bytes ||= @size_limit * 1024 * 1024
    end

    def raise_size_limit_error
      raise Errors::SizeLimitError,
            "There are only formulas above the size limit " \
            "(#{@size_limit} MB)."
    end

    def filter_by_max_version(formulas)
      formulas_with_version = detect_formula_version(formulas)
      max_version = formulas_with_version.map(&:first).max
      formulas_with_version.select do |version, _formula|
        version == max_version
      end.map(&:last)
    end

    def detect_formula_version(formulas)
      formulas.map do |formula|
        fonts = formula.fonts_by_name(@font_name)
        versions = fonts.flat_map do |font|
          font.styles.map do |style|
            StyleVersion.new(style.version)
          end
        end

        [versions.max, formula]
      end
    end

    def choose_smallest_formula(formulas)
      formulas.min_by do |formula|
        formula.file_size || 0
      end
    end
  end
end
