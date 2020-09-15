module Fontist
  module Utils
    module SevenZipExtractor
      def seven_zip_extract(resource, extension: /\.cab$/)
        file = download_file(resource)

        extract_seven_zip_file(file, extension)
      end

      private

      def extract_seven_zip_file(file, extension)
        File.open(file, "rb") do |zip_file|
          reader.open(zip_file) do |szr|
            path = extract_by_extension(szr, extension)

            return block_given? ? yield(path) : path
          end
        end
      end

      def reader
        @reader ||= begin
                      require "seven_zip_ruby"
                      SevenZipRuby::Reader
                    end
      end

      def extract_by_extension(szr, extension)
        cab_entry = szr.entries.detect do |entry|
          entry.file? && entry.path.match(extension)
        end

        szr.extract(cab_entry, temp_dir)
        filename = Pathname.new(cab_entry.path).basename
        File.join(temp_dir, filename)
      end

      def temp_dir
        @temp_dir ||= raise(
          NotImplementedError.new("You must implement this method")
        )
      end
    end
  end
end
