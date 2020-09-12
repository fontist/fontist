module Fontist
  module Utils
    module MsiExtractor
      def msi_extract(resource)
        file = download_file(resource)

        cab_path = temp_dir.join("data.cab").to_s
        cab_content = read_the_largest_file(file)
        File.write(cab_path, cab_content)

        block_given? ? yield(cab_path) : cab_path
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

      def temp_dir
        @temp_dir ||= raise(
          NotImplementedError.new("You must implement this method")
        )
      end
    end
  end
end
