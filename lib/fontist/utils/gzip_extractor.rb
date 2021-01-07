module Fontist
  module Utils
    module GzipExtractor
      def gzip_extract(resource)
        file = @downloaded ? resource : download_file(resource)

        extract_gzip_file(file)
      end

      private

      def extract_gzip_file(file)
        Zlib::GzipReader.open(file) do |gz|
          basename = File.basename(file, ".*")
          dir = Dir.mktmpdir
          path = File.join(dir, basename)
          File.write(path, gz.read, mode: "wb")

          path
        end
      end
    end
  end
end
