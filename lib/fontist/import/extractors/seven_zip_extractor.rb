module Fontist
  module Import
    module Extractors
      class SevenZipExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_7z(@archive, dir)
          dir
        end

        def try
          File.open(@archive, "rb") do |file|
            reader.open(file)
          end

          true
        rescue StandardError => e
          return false if e.message.start_with?("Invalid file format")

          raise
        end

        def format
          "seven_zip"
        end

        private

        def extract_7z(archive, dir)
          File.open(archive, "rb") do |file|
            reader.extract_all(file, dir)
          end
        end

        def reader
          @reader ||= begin
                        require "seven_zip_ruby"
                        SevenZipRuby::Reader
                      end
        end
      end
    end
  end
end
