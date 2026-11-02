require "cgi"
require "fileutils"

module Fontist
  # Web CSS for fonts.
  #
  # - {Css.url} / {Css.link}: Google Fonts CSS2 URL for a Google family.
  #   No network access, no font installation.
  # - {Css.local}: copies fonts already installed by fontist into a directory
  #   and writes a fonts.css with one @font-face per style.
  module Css
    class Error < Errors::GeneralError; end

    class UnknownFamilyError < Error
      def initialize(family)
        super("Font family '#{family}' was not found in the Fontist " \
              "formulas. Check the name, or run `fontist update`.")
      end
    end

    class AmbiguousFamilyError < Error
      def initialize(family, keys)
        super("Font family '#{family}' matches several Google formulas " \
              "(#{keys.join(', ')}); cannot choose one.")
      end
    end

    class NotGoogleFamilyError < Error
      def initialize(family)
        super("Font family '#{family}' is not a Google Fonts family, so " \
              "it has no Google CSS URL. Use `--local` to build CSS from " \
              "installed font files.")
      end
    end

    class InvalidStyleError < Error
      def initialize(style)
        super("Invalid style '#{style}'. Use a weight 100-900 with an " \
              "optional 'i' for italic, e.g. 400, 700i.")
      end
    end

    class UnavailableStyleError < Error
      def initialize(family, style, available)
        super("Style '#{style}' is not available for '#{family}'. " \
              "Available styles: #{available.join(', ')}.")
      end
    end

    class InvalidDisplayError < Error
      def initialize(display, allowed)
        super("Invalid display '#{display}'. Allowed: #{allowed.join(', ')}.")
      end
    end

    class InvalidOptionError < Error; end

    DISPLAYS = %w[auto block swap fallback optional].freeze
    GOOGLE_CSS2 = "https://fonts.googleapis.com/css2".freeze

    class << self
      # @param family [String] e.g. "Source Sans 3"
      # @param styles [Array<String>, String, nil] e.g. %w[300 600i]
      # @param display [String] auto|block|swap|fallback|optional
      # @return [String] the Google CSS2 URL (raw `&`)
      def url(family, styles: nil, display: "swap")
        display = validate_display(display)
        formula, canonical = GoogleFamily.resolve(family)
        requested = Styles.parse(styles)
        Styles.verify(canonical, Styles.faces(formula), requested)

        "#{GOOGLE_CSS2}?family=#{CGI.escape(canonical)}" \
          "#{axis_spec(requested)}&display=#{display}"
      end

      # @return [String] an HTML stylesheet link tag for {.url}
      def link(family, styles: nil, display: "swap")
        href = CGI.escapeHTML(url(family, styles: styles, display: display))
        %(<link rel="stylesheet" href="#{href}">)
      end

      # Copy installed fonts into output_dir and write fonts.css.
      # @return [String] path of the written fonts.css
      def local(family, output_dir:, **options)
        Local.new(family, output_dir: output_dir, **options).call
      end

      private

      def validate_display(display)
        value = display.to_s
        return value if DISPLAYS.include?(value)

        raise InvalidDisplayError.new(display, DISPLAYS)
      end

      def axis_spec(requested)
        return "" if requested.empty?
        return ":wght@#{requested.map(&:last).join(';')}" if
          requested.none? { |ital, _| ital == 1 }

        ":ital,wght@#{requested.map { |t| t.join(',') }.join(';')}"
      end
    end
  end
end

require_relative "css/styles"
require_relative "css/google_family"
require_relative "css/local"
