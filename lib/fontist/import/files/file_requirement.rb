require_relative "../helpers/system_helper"

module Fontist
  module Import
    module Files
      class FileRequirement
        def initialize
          `file -v`
        rescue Errno::ENOENT
          abort "`file` is not available. (Or is PATH not setup properly?)"
        end

        def call(path)
          Helpers::SystemHelper.run("file --brief '#{path}'")
        end
      end
    end
  end
end
