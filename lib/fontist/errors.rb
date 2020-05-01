module Fontist
  module Errors
    class LicensingError < StandardError; end
    class MissingFontError < StandardError; end
    class NonSupportedFontError < StandardError; end
  end
end
