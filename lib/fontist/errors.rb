module Fontist
  module Errors
    class GeneralError < StandardError; end
    class BinaryCallError < GeneralError; end
    class FontIndexCorrupted < GeneralError; end
    class FontNotFoundError < GeneralError; end
    class FormulaIndexNotFoundError < GeneralError; end
    class InvalidResourceError < GeneralError; end
    class LicensingError < GeneralError; end
    class ManifestCouldNotBeFoundError < GeneralError; end
    class ManifestCouldNotBeReadError < GeneralError; end
    class MissingAttributeError < GeneralError; end
    class MissingFontError < GeneralError; end
    class NonSupportedFontError < GeneralError; end
    class TamperedFileError < GeneralError; end
    class TimeoutError < GeneralError; end
    class UnknownFontTypeError < GeneralError; end
  end
end
