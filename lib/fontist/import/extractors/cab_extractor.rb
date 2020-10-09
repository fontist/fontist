module Fontist
  module Import
    module Extractors
      class CabExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_exe(@archive, dir)
          dir
        end

        def format
          File.extname(@archive) == ".exe" ? "exe" : "cab"
        end

        private

        def extract_exe(archive, dir)
          opened = decompressor.search(archive)
          file = opened.files

          while file
            path = File.join(dir, file.filename)
            decompressor.extract(file, path)
            file = file.next
          end
        end

        def decompressor
          @decompressor ||= begin
                              require "libmspack"
                              LibMsPack::CabDecompressor.new
                            end
        end
      end
    end
  end
end
