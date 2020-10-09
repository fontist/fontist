module Fontist
  module Import
    module Extractors
      class OleExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_ole(@archive, dir)
          dir
        end

        def format
          "msi"
        end

        private

        def extract_ole(archive, dir)
          ole = storage.open(archive)
          file = the_largest_file(ole)

          content = ole.file.read(file)
          path = File.join(dir, "data.cab")
          File.open(path, "wb") { |f| f.write(content) }
        end

        def storage
          @storage ||= begin
                         require "ole/storage"
                         Ole::Storage
                       end
        end

        def the_largest_file(ole)
          ole.dir.entries(".").max_by do |x|
            ole.file.size(x)
          end
        end
      end
    end
  end
end
