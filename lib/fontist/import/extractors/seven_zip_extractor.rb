module Fontist
  module Import
    module Extractors
      class SevenZipExtractor < Extractor
        def extension
          "exe"
        end

        def extract(pattern)
          Dir.mktmpdir do |tmp_dir|
            cab_path = extract_exe(@archive, tmp_dir)
            extract_cab(cab_path, tmp_dir, pattern).map do |path|
              yield path
            end
          end
        end

        def operations
          [{ format: "seven_zip" },
           { format: "cab" }]
        end

        private

        def extract_exe(archive, tmp_dir, extension: /\.cab$/)
          File.open(archive, "rb") do |zip_file|
            reader.open(zip_file) do |szr|
              cab_entry = szr.entries.detect do |entry|
                entry.file? && entry.path.match(extension)
              end

              szr.extract(cab_entry, tmp_dir)

              return path_from_entry(cab_entry, tmp_dir)
            end
          end
        end

        def reader
          @reader ||= begin
                        require "seven_zip_ruby"
                        SevenZipRuby::Reader
                      end
        end

        def path_from_entry(entry, tmp_dir)
          filename = Pathname.new(entry.path).basename
          File.join(tmp_dir, filename)
        end

        def extract_cab(cab_path, tmp_dir, pattern)
          cab_file = decompressor.search(cab_path)
          grep(cab_file.files, pattern).map do |file|
            path = File.join(tmp_dir, file.filename)
            decompressor.extract(file, path)
            path
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
