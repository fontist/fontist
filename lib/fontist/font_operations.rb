module Fontist
  # Font file operations backed by the Fontisan gem: collection member
  # extraction, collection bundling, format conversion and subsetting.
  #
  # Variable-font instancing is deliberately absent: Fontisan 0.4.46 cannot
  # produce a genuine static instance (see the README "Font operations").
  module FontOperations
    class Error < Errors::GeneralError; end

    autoload :Convert, "#{__dir__}/font_operations/convert"
    autoload :Extract, "#{__dir__}/font_operations/extract"
    autoload :Pack, "#{__dir__}/font_operations/pack"
    autoload :Subset, "#{__dir__}/font_operations/subset"

    # Runs the block, turning any Fontisan failure into FontOperations::Error
    # that names the operation.
    def self.guard(operation)
      require "fontisan"
      yield
    rescue Error, Errors::GeneralError
      raise
    rescue StandardError => e
      raise Error, "#{operation} failed: #{e.message}"
    end
  end
end
