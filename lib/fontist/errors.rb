module Fontist
  module Errors
    class LicensingError < StandardError; end
    class MissingFontError < StandardError; end
    class NonSupportedFontError < StandardError; end
    class TemparedFileError < StandardError; end
    class InvalidResourceError < StandardError; end
  end
end
