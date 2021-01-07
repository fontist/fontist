module Fontist
  module Import
    module Extractors
      class GzipExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_gzip(@archive, dir)
          dir
        end

        def format
          "gzip"
        end

        private

        def extract_gzip(archive, dir)
          Zlib::GzipReader.open(archive) do |gz|
            basename = File.basename(archive, ".*")
            path = File.join(dir, basename)
            File.write(path, gz.read)
          end
        end
      end
    end
  end
end
