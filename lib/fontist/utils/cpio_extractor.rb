module Fontist
  module Utils
    module CpioExtractor
      def cpio_extract(resource)
        file = @downloaded ? resource : download_file(resource)

        dir = extract_cpio_file(file)

        largest_file_in_dir(dir)
      end

      private

      def extract_cpio_file(archive_path)
        archive_file = File.open(archive_path, "rb")
        dir = Dir.mktmpdir
        extract_cpio_file_to_dir(archive_file, dir)

        dir
      end

      def extract_cpio_file_to_dir(archive_file, dir)
        cpio_reader_class.new(archive_file).each do |entry, file|
          path = File.join(dir, entry.name)
          if entry.directory?
            FileUtils.mkdir_p(path)
          else
            File.write(path, file.read, mode: "wb")
          end
        end
      end

      def cpio_reader_class
        @cpio_reader_class ||= begin
                                 require "fontist/utils/cpio/cpio"
                                 CPIO::ASCIIReader
                               end
      end

      def largest_file_in_dir(dir)
        Dir.glob(File.join(dir, "**/*")).max_by do |path|
          File.size(path)
        end
      end
    end
  end
end
