require "zip"

module Fontist
  module Import
    module Extractors
      class ZipExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_zip(@archive, dir)
          dir
        end

        def format
          "zip"
        end

        private

        def extract_zip(archive, dir)
          Zip::File.open(archive) do |zip_file|
            zip_file.each do |entry|
              path = File.join(dir, entry.name)
              FileUtils.mkdir_p(File.dirname(path))
              entry.extract(path)
            end
          end
        end
      end
    end
  end
end
