module Fontist
  # Font file operations backed by the Fontisan gem: collection member
  # extraction, collection bundling, format conversion, subsetting and
  # variable-font instancing.
  module FontOperations
    class Error < Errors::GeneralError; end

    autoload :Convert, "#{__dir__}/font_operations/convert"
    autoload :Extract, "#{__dir__}/font_operations/extract"
    autoload :Instance, "#{__dir__}/font_operations/instance"
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
