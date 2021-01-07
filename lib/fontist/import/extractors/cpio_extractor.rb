module Fontist
  module Import
    module Extractors
      class CpioExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_cpio(@archive, dir)
          dir
        end

        def format
          "cpio"
        end

        private

        def extract_cpio(archive, dir)
          archive_file = File.open(archive, "rb")

          reader_class.new(archive_file).each do |entry, file|
            path = File.join(dir, entry.name)
            if entry.directory?
              FileUtils.mkdir_p(path)
            else
              File.write(path, file.read)
            end
          end
        end

        def reader_class
          @reader_class ||= begin
                              require "fontist/utils/cpio/cpio"
                              CPIO::ASCIIReader
                            end
        end
      end
    end
  end
end
