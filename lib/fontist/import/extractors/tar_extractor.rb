module Fontist
  module Import
    module Extractors
      class TarExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_tar(@archive, dir)
          dir
        end

        def format
          "tar"
        end

        private

        def extract_tar(archive, dir)
          archive_file = File.open(archive, "rb")
          reader_class.new(archive_file) do |tar|
            tar.each do |tarfile|
              save_tar_file(tarfile, dir)
            end
          end
        end

        def reader_class
          @reader_class ||= begin
                              require "rubygems/package"
                              Gem::Package::TarReader
                            end
        end

        def save_tar_file(file, dir)
          path = File.join(dir, file.full_name)

          if file.directory?
            FileUtils.mkdir_p(path)
          else
            File.open(path, "wb") do |f|
              f.print(file.read)
            end
          end
        end
      end
    end
  end
end
