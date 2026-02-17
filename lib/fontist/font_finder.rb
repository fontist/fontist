require_relative "format_spec"
require_relative "format_matcher"

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

      matching_formulas.flat_map do |formula|
        next [] unless formula.v5?

        each_resource(formula).select do |_name, resource|
          resource.variable_font? && axes_supported?(resource, axes)
        end.map do |name, resource|
          build_font_match(formula, name, resource)
        end
      end.flatten
    end

    # Find all variable fonts
    def variable_fonts
      matching_formulas.flat_map do |formula|
        next [] unless formula.v5?

        each_resource(formula).select do |_, r|
          r.variable_font?
        end.map do |name, resource|
          build_font_match(formula, name, resource)
        end
      end.flatten
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

    # Helper to iterate over resources as [name, resource] pairs
    def each_resource(formula)
      return [] unless formula.resources

      # ResourceCollection has a resources attribute that contains the array
      resources_array = if formula.resources.is_a?(ResourceCollection)
                          formula.resources.resources
                        else
                          formula.resources
                        end

      Array(resources_array).map { |r| [r.name, r] }
    end

    def extract_resource_names(formula)
      return [] unless formula.resources

      # ResourceCollection has a resources attribute that contains the array
      resources_array = if formula.resources.is_a?(ResourceCollection)
                          formula.resources.resources
                        else
                          formula.resources
                        end

      Array(resources_array).map(&:name).compact
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
      # Heuristics for common patterns
      return "monospace" if name.match?(/mono/i)
      return "serif" if name.match?(/serif/i)

      "sans-serif"
    end
  end

  # Result object for font matches
  class FontMatch
    attr_reader :name, :resource, :axes, :format, :category, :resources

    def initialize(name:, resource: nil, axes: [], format: nil,
                   category: nil, resources: nil)
      @name = name
      @resource = resource
      @axes = axes
      @format = format
      @category = category
      @resources = resources
    end

    def to_h
      {
        name: name,
        resource: resource,
        axes: axes,
        format: format,
        category: category,
      }.compact
    end
  end
end
