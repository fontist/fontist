module Fontist
  module Errors
    class LicensingError < StandardError; end
    class MissingFontError < StandardError; end
    class NonSupportedFontError < StandardError; end
    class TamperedFileError < StandardError; end
    class InvalidResourceError < StandardError; end
    class TimeoutError < StandardError; end
  end
end
