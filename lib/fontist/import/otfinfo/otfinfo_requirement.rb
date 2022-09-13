require "fontist/import/helpers/system_helper"

module Fontist
  module Import
    module Otfinfo
      class OtfinfoRequirement
        def initialize
          otfinfo_path = `which otfinfo`
          if otfinfo_path.empty?
            abort "otfinfo is not available. (Or is PATH not setup properly?)" \
                  " You must install otfinfo." \
                  " On macOS it can be installed via `brew install lcdf-typetools`."
          end
        end

        def call(path)
          Helpers::SystemHelper.run("otfinfo --info '#{path}'")
        end
      end
    end
  end
end
