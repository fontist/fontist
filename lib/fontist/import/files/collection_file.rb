require "extract_ttc"
require "fontist/import/helpers/system_helper"
require_relative "../otf/font_file"

module Fontist
  module Import
    module Files
      class CollectionFile
        attr_reader :fonts

        def initialize(path, name_prefix: nil)
          @path = path
          @name_prefix = name_prefix
          @fonts = read
          @extension = detect_extension
        end

        def filename
          File.basename(@path, ".*") + "." + @extension
        end

        def source_filename
          File.basename(@path) unless filename == File.basename(@path)
        end

        private

        def read
          Dir.mktmpdir do |tmp_dir|
            extract_ttfs(tmp_dir)
              .map { |path| Otf::FontFile.new(path, name_prefix: @name_prefix) }
              .reject { |font_file| hidden_or_pua_encoded?(font_file) }
          end
        end

        def extract_ttfs(tmp_dir)
          ExtractTtc.extract(@path, output_dir: tmp_dir)
        end

        def hidden_or_pua_encoded?(font_file)
          font_file.family_name.start_with?(".")
        end

        def detect_extension
          base_extension = "ttc"

          file_extension = File.extname(File.basename(@path)).sub(/^\./, "")
          return file_extension if file_extension.casecmp?(base_extension)

          base_extension
        end
      end
    end
  end
end
