require "zip"

module Fontist
  module Import
    module Extractors
      class ZipExtractor < Extractor
        BOTH_FONTS_PATTERN = "**/*.{ttf,otf,ttc}".freeze

        def extension
          "zip"
        end

        def extract(pattern)
          Dir.mktmpdir do |tmp_dir|
            Zip::File.open(@archive) do |zip_file|
              zip_file.select { |file| file.name.match(pattern) }.map do |entry|
                filename = Pathname.new(entry.name).basename
                path = File.join(tmp_dir, filename)
                entry.extract(path)
                yield path
              end
            end
          end
        end

        def operations
          zip_file = Zip::File.open(@archive)
          sub_dirs = zip_file.glob(BOTH_FONTS_PATTERN).map do |entry|
            File.split(entry.name).first
          end

          options = { fonts_sub_dir: "**/*/" } unless sub_dirs.uniq == ["."]

          { format: "zip", options: options }.compact
        end
      end
    end
  end
end
