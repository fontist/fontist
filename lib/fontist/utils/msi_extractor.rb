module Fontist
  module Utils
    module MsiExtractor
      def msi_extract(resource)
        file = @downloaded ? resource : download_file(resource)

        cab_content = read_the_largest_file(file)

        cab_file = Tempfile.new(["data", ".cab"], mode: File::BINARY)
        cab_file.write(cab_content)

        block_given? ? yield(cab_file.path) : cab_file.path
      end

      private

      def read_the_largest_file(file)
        ole = storage.open(file)
        the_largest_file = ole.dir.entries(".").max_by { |x| ole.file.size(x) }
        ole.file.read(the_largest_file)
      end

      def storage
        @storage ||= begin
                       require "ole/storage"
                       Ole::Storage
                     end
      end
    end
  end
end
