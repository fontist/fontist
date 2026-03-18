require_relative "format_matcher"

module Fontist
  class FormulaPicker
    def initialize(font_name,
                   size_limit: nil, version: nil, smallest: nil, newest: nil,
                   format_spec: nil)
      @font_name = font_name
      @size_limit = size_limit || Fontist.formula_size_limit_in_megabytes
      @format_spec = format_spec

      @options = {}
      @version = @options[:version] = version if version
      @smallest = @options[:smallest] = smallest if smallest
      @newest = @options[:newest] = newest if newest
    end

    def call(formulas)
      return [] if formulas.empty?

      list = filter(formulas)
      return [] if list.empty?

      # Use FormatMatcher for format filtering
      list = filter_by_format_spec(list) if @format_spec&.has_constraints?

      choose(list)
    end

    private

    def filter(formulas)
      list = formulas

      list = filter_by_passed_version(formulas) if @version
      return [] if list.empty?

      list = ensure_size_limit(list) if @options.empty?

      ensure_fontist_version(list)
    end

    def filter_by_format_spec(formulas)
      matcher = FormatMatcher.new(@format_spec)

      formulas.map do |formula|
        next formula unless formula.v5?

        matching = matcher.filter_resources(formula.resources)
        if matching.any?
          formula.dup.tap { |f| f.resources = matching }
        end
      end.compact
    end

    def ensure_fontist_version(formulas)
      suitable, unsuitable = filter_by_fontist_version(formulas)
      raise_fontist_version_error(unsuitable) if suitable.empty?

      suitable
    end

    def filter_by_fontist_version(formulas)
      suitable, unsuitable = formulas.partition do |f|
        f.min_fontist.nil? ||
          Gem::Version.new(Fontist::VERSION) >= Gem::Version.new(f.min_fontist)
      end

      unless unsuitable.empty?
        print_formulas_with_unsuitable_fontist_version(unsuitable)
      end

      [suitable, unsuitable]
    end

    def print_formulas_with_unsuitable_fontist_version(formulas)
      Fontist.ui.debug(
        "Some formulas were excluded from choice, because they require " \
        "higher version of fontist: #{formulas_versions(formulas)}. " \
        "Current fontist version: #{Fontist::VERSION}.",
      )
    end

    def raise_fontist_version_error(formulas)
      raise Fontist::Errors::FontistVersionError,
            "Suitable formulas require higher version of fontist. " \
            "Please upgrade fontist.\n" \
            "Minimum required version: #{formulas_versions(formulas)}. " \
            "Current fontist version: #{Fontist::VERSION}."
    end

    def formulas_versions(formulas)
      formulas.map { |f| "#{f.key} (#{f.min_fontist})" }.join(", ")
    end

    def filter_by_passed_version(formulas)
      formulas.select do |formula|
        contain_passed_version?(formula)
      end
    end

    def contain_passed_version?(formula)
      fonts = formula.fonts_by_name(@font_name)
      fonts.each do |font|
        font.styles.each do |style|
          version = StyleVersion.new(style.version)
          return true if version == passed_version
        end
      end

      false
    end

    def passed_version
      @passed_version ||= StyleVersion.new(@version)
    end

    def choose(formulas)
      return formulas if contain_different_styles?(formulas)

      list = formulas

      if @options.empty? || @newest
        list = choose_max_version(list)
      end

      smallest(list)
    end

    def smallest(formulas)
      [choose_smallest_formula(formulas)]
    end

    def choose_smallest_formula(formulas)
      formulas.min_by do |formula|
        formula.file_size || 0
      end
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

    def ensure_size_limit(formulas)
      list = filter_by_size_limit(formulas)
      raise_size_limit_error if list.empty?

      list
    end

    def filter_by_size_limit(formulas)
      formulas.select do |formula|
        formula.file_size.nil? || resources_cached?(formula) ||
          formula.file_size < size_limit_in_bytes
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

    def choose_max_version(formulas)
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

    def resources_cached?(formula)
      Utils::Cache.new.already_fetched?(
        formula.resources.flat_map(&:urls),
      )
    end
  end
end
