require "extract_ttc"
require "fontist/import/helpers/system_helper"
require_relative "../otf/font_file"

module Fontist
  module Import
    module Files
      class CollectionFile
        attr_reader :fonts

        def initialize(path)
          @path = path
          @fonts = read
          @extension = "ttc"
        end

        def filename
          File.basename(@path, ".*") + "." + @extension
        end

        def source_filename
          File.basename(@path) unless filename == File.basename(@path)
        end

        private

        def read
          switch_to_temp_dir do |tmp_dir|
            extract_ttfs(tmp_dir).map do |path|
              Otf::FontFile.new(path)
            end
          end
        end

        def switch_to_temp_dir
          Dir.mktmpdir do |tmp_dir|
            Dir.chdir(tmp_dir) do
              yield tmp_dir
            end
          end
        end

        def extract_ttfs(tmp_dir)
          filenames = ExtractTtc.extract(@path)
          filenames.map do |filename|
            File.join(tmp_dir, filename)
          end
        end
      end
    end
  end
end
