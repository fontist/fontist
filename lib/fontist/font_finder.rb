require_relative "format_spec"
require_relative "format_matcher"
require_relative "utils/google_css_url"

module Fontist
  # Find fonts by their capabilities (axes, formats, etc.)
  #
  # Supports:
  # - Find fonts with specific variable axes
  # - Find fonts with any variable support
  # - Find fonts by category (sans-serif, monospace, etc.)
  #
  # Examples:
  #   FontFinder.by_axes(["wght", "wdth"])  # Fonts with both axes
  #   FontFinder.variable_fonts             # All variable fonts
  #   FontFinder.by_category("monospace")   # Monospace fonts
  #
  class FontFinder
    def initialize(format_spec: nil, category: nil)
      @format_spec = format_spec
      @category = category
    end

    # Find fonts that support ALL specified axes
    def by_axes(axes)
      raise ArgumentError, "axes must be an array" unless axes.is_a?(Array)

      results = matching_formulas.flat_map do |formula|
        next [] unless formula.v5?

        resources = each_resource(formula)
        resources = apply_format_filter(resources)
        resources.select do |resource|
          resource.variable_font? && axes_supported?(resource, axes)
        end.map do |resource|
          build_font_match(formula, resource.name, resource)
        end
      end.flatten
    end

    # Find all variable fonts
    def variable_fonts
      matching_formulas.flat_map do |formula|
        next [] unless formula.v5?

        resources = each_resource(formula)
        resources = apply_format_filter(resources)
        resources.select(&:variable_font?).map do |resource|
          build_font_match(formula, resource.name, resource)
        end
      end.flatten
    end

    # Get CSS URL for a font (web-enabled format support)
    def css_url_for(font_name)
      normalized = font_name.downcase.gsub(/[\s_-]+/, "_")
      Formula.all.each do |formula|
        formula_normalized = formula.name&.downcase&.gsub(/[\s_-]+/, "_")
        next unless formula_normalized == normalized

        Array(formula.resources).each do |resource|
          return resource.css_url if resource.css_url
        end

        # Auto-generate Google Fonts CSS URL if source is google
        Array(formula.resources).each do |resource|
          if resource.source == "google" && resource.family
            return build_google_css_url(resource.family, formula)
          end
        end
      end
      nil
    end

    # Find fonts by category
    def by_category(category)
      matching_formulas.select do |formula|
        extract_category(formula) == category
      end.map do |formula|
        resource_names = extract_resource_names(formula)
        FontMatch.new(
          name: formula.name,
          resources: resource_names,
          category: category,
        )
      end
    end

    private

    def each_resource(formula)
      return [] unless formula.resources

      Array(formula.resources)
    end

    def extract_resource_names(formula)
      return [] unless formula.resources

      Array(formula.resources).map(&:name).compact
    end

    def build_font_match(formula, name, resource)
      FontMatch.new(
        name: formula.name,
        resource: name,
        axes: resource.axes_tags,
        format: resource.format,
        category: extract_category(formula),
      )
    end

    def matching_formulas
      @matching_formulas ||= Formula.all.select do |formula|
        next false if @category && extract_category(formula) != @category

        true
      end
    end

    def axes_supported?(resource, required_axes)
      available = resource.axes_tags
      required_axes.all? { |axis| available.include?(axis.to_s) }
    end

    def extract_category(formula)
      # Extract from formula metadata if available
      # Note: Formula does not have a category attribute currently
      # Category is detected from name heuristics
      detect_category_from_name(formula.name)
    end

    def detect_category_from_name(name)
      return "monospace" if name.match?(/mono(space)?/i)
      return "sans-serif" if name.match?(/sans[-\s]?serif/i) || name.match?(/\bsans\b/i)
      return "serif" if name.match?(/serif/i)

      "sans-serif"
    end

    def apply_format_filter(resources)
      return resources unless @format_spec&.has_constraints?

      matcher = FormatMatcher.new(@format_spec)
      matcher.filter_resources(resources)
    end

    def build_google_css_url(family, formula)
      variants = Utils::GoogleCssUrl.variants_from_weights(
        weights_from_formula(formula),
      )
      Utils::GoogleCssUrl.build(family, variants)
    end

    def weights_from_formula(formula)
      styles = []
      formula.all_fonts.each do |font|
        styles.concat(Array(font.styles)) if font.respond_to?(:styles)
      end

      styles.filter_map do |style|
        type = (style.respond_to?(:preferred_type) && style.preferred_type) ||
               (style.respond_to?(:type) && style.type)
        next unless type

        Utils::GoogleCssUrl.weight_from_name(type)
      end
    end
  end

  # Result object for font matches
  class FontMatch
    attr_reader :name, :resource, :axes, :format, :category, :resources, :css_url

    def initialize(name:, resource: nil, axes: [], format: nil,
                   category: nil, resources: nil, css_url: nil)
      @name = name
      @resource = resource
      @axes = axes
      @format = format
      @category = category
      @resources = resources
      @css_url = css_url
    end

    def to_h
      {
        name: name,
        resource: resource,
        axes: axes,
        format: format,
        category: category,
        css_url: css_url,
      }.compact
    end
  end
end
