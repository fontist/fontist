require "fontisan"
require "tempfile"
require_relative "../otf/font_file"

module Fontist
  module Import
    module Files
      class CollectionFile
        class << self
          def from_path(path, name_prefix: nil)
            collection = build_collection(path)
            new(collection, path, name_prefix)
          end

          private

          def build_collection(path)
            Fontisan::TrueTypeCollection.from_file(path)
          rescue StandardError => e
            raise Errors::FontFileError,
                  "Font collection could not be parsed: #{e.inspect}"
          end
        end

        attr_reader :fonts

        def initialize(fontisan_collection, path, name_prefix = nil)
          @collection = fontisan_collection
          @path = path
          @name_prefix = name_prefix
          @fonts = extract_fonts
        end

        def filename
          "#{File.basename(@path, '.*')}.#{extension}"
        end

        def source_filename
          File.basename(@path) unless filename == File.basename(@path)
        end

        private

        def extract_fonts
          Array.new(@collection.num_fonts) do |index|
            extract_font_at(index)
          end
        end

        def extract_font_at(index)
          tmpfile = Tempfile.new(["font", ".ttf"])
          tmpfile.binmode

          File.open(@path, "rb") do |io|
            font = @collection.font(index, io)
            font.to_file(tmpfile.path)
          end

          tmpfile.close
          Otf::FontFile.new(tmpfile.path, name_prefix: @name_prefix)
        end

        def hidden?(font_file)
          font_file.family_name.start_with?(".")
        end

        def extension
          @extension ||= detect_extension
        end

        def detect_extension
          base = "ttc"
          file_ext = File.extname(File.basename(@path)).sub(/^\./, "")
          file_ext.casecmp?(base) ? file_ext : base
        end
      end
    end
  end
end
