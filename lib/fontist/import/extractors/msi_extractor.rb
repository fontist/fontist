module Fontist
  module Import
    module Extractors
      class MsiExtractor < Extractor
        def extension
          "msi"
        end

        def extract(pattern)
          Dir.mktmpdir do |tmp_dir|
            cab_path = extract_msi(@archive, tmp_dir)
            extract_cab(cab_path, tmp_dir, pattern).map do |path|
              yield path
            end
          end
        end

        def operations
          [{ format: "msi" },
           { format: "cab" }]
        end

        private

        def extract_msi(archive, tmp_dir)
          ole = storage.open(archive)
          the_largest_file = ole.dir.entries(".").max_by do |x|
            ole.file.size(x)
          end

          cab_content = ole.file.read(the_largest_file)
          cab_path = File.join(tmp_dir, "data.cab")
          File.write(cab_path, cab_content)

          cab_path
        end

        def extract_cab(cab_path, tmp_dir, pattern)
          cab_file = decompressor.search(cab_path)
          grep(cab_file.files, pattern).map do |file|
            path = File.join(tmp_dir, file.filename)
            decompressor.extract(file, path)
            path
          end
        end

        def storage
          @storage ||= begin
                         require "ole/storage"
                         Ole::Storage
                       end
        end

        def grep(file, pattern)
          Array.new.tap do |result|
            while file
              result.push(file) if file.filename.match(pattern)
              file = file.next
            end
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
