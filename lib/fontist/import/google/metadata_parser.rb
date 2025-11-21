# frozen_string_literal: true

# TODO: We should properly parse Protobuf files (METADATA.pb) instead of using
# ad-hoc parsers. However, there is no current Ruby Protobuf library that
# supports parsing Protobuf text format files. ruby-protobuf only supports
# binary format, and google-protobuf gem requires compiled extensions.

module Fontist
  module Import
    module Google
      # Parser for Google Fonts METADATA.pb files
      #
      # Parses protobuf text format files and provides OO access to metadata
      class MetadataParser
        attr_reader :name, :designer, :license, :category, :date_added,
                    :font_files

        def initialize(file_path_or_content)
          @content = if File.exist?(file_path_or_content.to_s)
                       File.read(file_path_or_content, encoding: "UTF-8")
                     else
                       file_path_or_content
                     end

          parse
        end

        # Returns array of font filenames
        #
        # @return [Array<String>] font filenames
        def filenames
          @font_files.map { |f| f[:filename] }
        end

        # Returns hash representation
        #
        # @return [Hash] metadata hash
        def to_h
          {
            name: @name,
            designer: @designer,
            license: @license,
            category: @category,
            date_added: @date_added,
            font_files: @font_files,
          }
        end

        private

        def parse
          # Parse root-level fields
          @name = extract_field("name")
          @designer = extract_field("designer")
          @license = extract_field("license")
          @category = extract_field("category")
          @date_added = extract_field("date_added")

          # Extract font file entries
          @font_files = extract_font_files
        end

        def extract_field(field_name)
          @content[/^#{field_name}:\s*"([^"]*)"/, 1]
        end

        def extract_font_files
          fonts = []

          @content.scan(/fonts\s*\{([^}]+)\}/m) do |match|
            font_block = match[0]

            filename = font_block[/filename:\s*"([^"]*)"/, 1]
            next unless filename

            fonts << {
              filename: filename,
              name: font_block[/name:\s*"([^"]*)"/, 1],
              style: font_block[/style:\s*"([^"]*)"/, 1],
              weight: font_block[/weight:\s*(\d+)/, 1]&.to_i,
              post_script_name: font_block[/post_script_name:\s*"([^"]*)"/, 1],
              full_name: font_block[/full_name:\s*"([^"]*)"/, 1],
              copyright: font_block[/copyright:\s*"([^"]*)"/, 1],
            }
          end

          fonts
        end
      end
    end
  end
end
