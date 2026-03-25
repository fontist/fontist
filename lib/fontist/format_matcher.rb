module Fontist
  # Centralized format matching service
  #
  # All format matching logic exists here. Other classes delegate to this.
  # Supports matching across:
  # - Resources (formula download sources)
  # - Styles (font style entries)
  # - Indexed fonts (system/user/fontist indexes)
  # - Collections (TTC/OTC with multiple fonts)
  #
  # For transcoding, delegates to Fontisan library.
  class FormatMatcher
    # All supported formats
    DESKTOP_FORMATS = %w[ttf otf ttc otc dfont].freeze
    WEB_FORMATS = %w[woff woff2].freeze
    ALL_FORMATS = (DESKTOP_FORMATS + WEB_FORMATS).freeze

    def initialize(format_spec)
      @spec = format_spec || FormatSpec.new
    end

    # Check if a resource matches the format spec
    def matches_resource?(resource)
      return true unless @spec.has_constraints?

      if @spec.format && resource.format && resource.format != @spec.format
        return false
      end

      if @spec.variable_requested?
        return false unless resource.variable_font?
        return axes_match?(resource.variable_axes) if @spec.axes.any?
      end

      true
    end

    # Check if a style matches the format spec
    # @param style [FontStyle, SystemIndexFont] Style object to check
    def matches_style?(style)
      return true unless @spec.has_constraints?

      # Check format constraint for FontStyle (v5 formulas have formats)
      if @spec.format && style.is_a?(FontStyle) && style.formats && !Array(style.formats).include?(@spec.format)
        return false
      end

      if @spec.variable_requested?
        # Check if style is variable
        is_variable = style.variable_font?
        return false unless is_variable

        return axes_match?(style.variable_axes) if @spec.axes.any?
      end

      true
    end

    # Check if an indexed font matches the format spec
    def matches_indexed_font?(indexed_font)
      return true unless @spec.has_constraints?
      return false if @spec.format && indexed_font.format != @spec.format

      if @spec.variable_requested?
        return false unless indexed_font.variable_font

        return axes_match?(indexed_font.variable_axes) if @spec.axes.any?
      end

      true
    end

    # Filter resources to only matching ones
    def filter_resources(resources)
      resources.select { |r| matches_resource?(r) }
    end

    # Filter styles to only matching ones
    def filter_styles(styles)
      styles.select { |s| matches_style?(s) }
    end

    # Filter indexed fonts to only matching ones
    def filter_indexed_fonts(fonts)
      fonts.select { |f| matches_indexed_font?(f) }
    end

    # Select best resource based on preferences
    def select_preferred_resource(resources)
      return resources.first if resources.empty?
      return resources.first unless @spec.has_constraints?

      # Match exact format first (e.g. format: "ttf" selects the ttf resource)
      exact = find_exact_format(resources)
      return exact if exact

      preferred = find_preferred_format(resources)
      return preferred if preferred

      variable = find_variable_resource(resources)
      return variable if variable

      resources.first
    end

    # Check if requested format needs transcoding from available formats
    def installation_strategy(available_formats)
      requested = @spec.format

      if !requested
        return { strategy: :install, format: available_formats.first }
      end

      if available_formats.include?(requested)
        return { strategy: :install, format: requested }
      end

      # Check if Fontisan can convert from any available format
      convertible = available_formats.find { |f| self.class.can_convert?(f, requested) }
      if convertible
        return {
          strategy: :convert,
          from: convertible,
          to: requested,
        }
      end

      {
        strategy: :unavailable,
        requested: requested,
        available: available_formats,
      }
    end

    # Check if Fontisan can convert between formats (instance method for convenience)
    def can_convert?(from_format, to_format)
      self.class.can_convert?(from_format, to_format)
    end

    # Class method for checking Fontisan conversion capability
    def self.can_convert?(from_format, to_format)
      return false unless from_format && to_format

      # Fontisan supports conversion from desktop to web formats
      DESKTOP_FORMATS.include?(from_format.to_s) &&
        WEB_FORMATS.include?(to_format.to_s)
    end

    private

    def find_exact_format(resources)
      return nil unless @spec.format

      resources.find { |r| r.format == @spec.format }
    end

    def find_preferred_format(resources)
      return nil unless @spec.prefer_format

      resources.find { |r| r.format == @spec.prefer_format }
    end

    def find_variable_resource(resources)
      return nil unless @spec.prefer_variable

      resources.find { |r| r.variable_font? }
    end

    def axes_match?(available_axes)
      return true if @spec.axes.empty?

      available = Array(available_axes).map(&:to_s)
      @spec.axes.all? { |axis| available.include?(axis) }
    end
  end
end
