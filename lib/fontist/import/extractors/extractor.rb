module Fontist
  module Import
    module Extractors
      class Extractor
        def initialize(archive)
          @archive = archive
        end

        def extract
          raise NotImplementedError.new("You must implement this method")
        end

        def format
          raise NotImplementedError.new("You must implement this method")
        end
      end
    end
  end
end
