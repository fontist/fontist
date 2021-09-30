module Fontist
  module Errors
    class GeneralError < StandardError; end

    class BinaryCallError < GeneralError; end

    class FontIndexCorrupted < GeneralError; end

    class FontNotFoundError < GeneralError; end

    # for backward compatibility with metanorma,
    # it depends on this exception to automatically download formulas
    class FormulaIndexNotFoundError < GeneralError; end

    class MainRepoNotFoundError < FormulaIndexNotFoundError; end

    class InvalidResourceError < GeneralError; end

    class LicensingError < GeneralError; end

    class ManifestCouldNotBeFoundError < GeneralError; end

    class ManifestCouldNotBeReadError < GeneralError; end

    class MissingAttributeError < GeneralError; end

    class RepoNotFoundError < GeneralError; end

    class RepoCouldNotBeUpdatedError < GeneralError; end

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
  end
end
