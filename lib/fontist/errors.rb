module Fontist
  module Errors
    class GeneralError < StandardError; end

    class BinaryCallError < GeneralError; end

    class FontconfigNotFoundError < GeneralError
      def initialize
        super("Could not find fontconfig.")
      end
    end

    class FontconfigFileNotFoundError < GeneralError
      def initialize
        super("Fontist file could not be found in fontconfig configuration.")
      end
    end

    class FontIndexCorrupted < GeneralError; end

    class FontFileError < GeneralError; end

    class FontExtractError < GeneralError; end

    class FontistVersionError < GeneralError; end

    class FontNotFoundError < GeneralError
      attr_reader :parsing_errors

      def initialize(message, parsing_errors: [])
        super(message)
        @parsing_errors = Array(parsing_errors)
      end

      def has_parsing_errors?
        @parsing_errors && @parsing_errors.any?
      end
    end

    # for backward compatibility with metanorma,
    # it depends on this exception to automatically download formulas
    class FormulaIndexNotFoundError < GeneralError; end

    class FormulaInvalidError < GeneralError; end

    class FormulaNotFoundError < GeneralError
      def initialize(formula)
        super(<<~MSG.chomp)
          Formula '#{formula}' not found locally nor available in the Fontist formula repository.
          Perhaps it is available at the latest Fontist formula repository.
          You can update the formula repository using the command `fontist update` and try again.
        MSG
      end
    end

    class MainRepoNotFoundError < FormulaIndexNotFoundError; end

    class InvalidConfigAttributeError < GeneralError; end

    class InvalidResourceError < GeneralError; end

    class LicensingError < GeneralError; end

    class ManifestCouldNotBeFoundError < GeneralError; end

    class ManifestCouldNotBeReadError < GeneralError; end

    class MissingAttributeError < GeneralError; end

    class RepoNotFoundError < GeneralError; end

    class RepoCouldNotBeUpdatedError < GeneralError; end

    class SizeLimitError < GeneralError; end

    class TamperedFileError < GeneralError; end

    class TimeoutError < GeneralError; end

    class UnknownFontTypeError < GeneralError; end

    class UnknownArchiveError < GeneralError; end

    class FontError < GeneralError
      attr_reader :font, :style

      def initialize(msg, font = nil, style = nil)
        @font = font
        @style = style

        super(msg)
      end

      def name
        messages = []
        messages << "Font name: '#{@font}'"
        messages << "Style: '#{@style}'" if @style
        messages.join("; ")
      end
    end

    class MissingFontError < FontError
      def initialize(font, style = nil)
        name = prepare_name(font, style)
        msg = "#{name} font is missing, please run `fontist install '#{font}'` to download the font."

        super(msg, font, style)
      end

      private

      def prepare_name(font, style)
        names = []
        names << "'#{font}'"
        names << "'#{style}'" if style
        names.join(" ")
      end
    end

    class ManualFontError < FontError
      def initialize(font, formula)
        msg = "'#{font}' font is missing.\n\n#{formula.instructions}"

        super(msg, font)
      end
    end

    class UnsupportedFontError < FontError
      def initialize(font)
        msg = <<~MSG.chomp
          Font '#{font}' not found locally nor available in the Fontist formula repository.
          Perhaps it is available at the latest Fontist formula repository.
          You can update the formula repository using the command `fontist update` and try again.
        MSG

        super(msg, font)
      end
    end

    class PlatformMismatchError < FontError
      attr_reader :required_platforms, :current_platform

      def initialize(font_name, required_platforms, current_platform)
        @required_platforms = Array(required_platforms)
        @current_platform = current_platform

        msg = build_message(font_name)
        super(msg, font_name)
      end

      private

      def build_message(font_name)
        "Font '#{font_name}' is only available for: #{@required_platforms.join(', ')}. " \
        "Your current platform is: #{@current_platform}. " \
        "This font is licensed exclusively for the specified platform(s) and " \
        "cannot be installed on your system."
      end
    end
  end
end
