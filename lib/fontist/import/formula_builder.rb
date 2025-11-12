require "shellwords"
require_relative "text_helper"
require_relative "helpers/hash_helper"

module Fontist
  module Import
    class FormulaBuilder
      FORMULA_ATTRIBUTES = %i[name platforms description homepage resources
                              font_collections fonts extract copyright
                              license_url requires_license_agreement
                              open_license digest command].freeze

      attr_writer :resources,
                  :options,
                  :font_files,
                  :font_collection_files,
                  :license_text,
                  :operations

      def initialize
        @options = {}
        @font_files = []
        @font_collection_files = []
      end

      def formula
        formula_attributes.to_h { |name| [name, send(name)] }.compact
      end

      def save
        path = vacant_path
        yaml = YAML.dump(Helpers::HashHelper.stringify_keys(formula))
        File.write(path, yaml)
        path
      end

      private

      def formula_attributes
        FORMULA_ATTRIBUTES
      end

      def name
        @name ||= generate_name
      end

      def generate_name
        return @options[:name] if @options[:name]

        common = common_prefix
        return common unless common.empty?

        both_fonts.map(&:family_name).first
      end

      def common_prefix
        family_prefix = common_prefix_by_attr(:family_name)
        style_prefix = common_prefix_by_attr(:type)

        [family_prefix, style_prefix].compact.join(" ")
      end

      def common_prefix_by_attr(attr)
        names = both_fonts.map(&attr).uniq
        prefix = TextHelper.longest_common_prefix(names)

        prefix unless prefix == "Regular"
      end

      def both_fonts
        @both_fonts ||= group_fonts
      end

      def group_fonts
        files = (@font_files + @font_collection_files.map(&:fonts)).flatten
        raise Errors::FontNotFoundError, "No font found" if files.empty?

        files
      end

      def platforms
        @options[:platforms]
      end

      def description
        name
      end

      def homepage
        @options[:homepage] || both_fonts.filter_map(&:homepage).first
      end

      def resources
        @resources || raise("Resources should be set.")
      end

      def font_collections
        return if @font_collection_files.empty?

        collections = @font_collection_files.map do |file|
          fonts = fonts_from_files(file.fonts, :to_collection_style)

          { filename: file.filename,
            source_filename: file.source_filename,
            fonts: fonts }.compact
        end

        collections.sort_by do |x|
          x[:filename]
        end
      end

      def fonts
        return if @font_files.empty?

        fonts_from_files(@font_files, :to_style)
      end

      def fonts_from_files(files, style_type = :to_style)
        groups = files.group_by(&:family_name)

        fonts = groups.map do |name, group|
          { name: name,
            styles: styles_from_files(group, style_type) }
        end

        fonts.sort_by do |x|
          x[:name]
        end
      end

      def styles_from_files(files, style_type)
        files.map(&style_type).sort_by { |x| x[:type] }
      end

      def extract
        @operations || {}
      end

      def copyright
        both_fonts.filter_map(&:copyright).first
      end

      def license_url
        both_fonts.filter_map(&:license_url).first
      end

      def requires_license_agreement
        @options[:requires_license_agreement]
      end

      def open_license
        unless @license_text || requires_license_agreement
          Fontist.ui.error("WARN: please add license manually")
        end

        return unless @license_text

        unless @options[:open_license]
          Fontist.ui.error("WARN: ensure it's an open license, otherwise " \
                           "change the 'open_license' attribute to " \
                           "'requires_license_agreement'")
        end

        TextHelper.cleanup(@license_text)
      end

      def digest
        @options[:digest]
      end

      def command
        Shellwords.shelljoin(ARGV)
      end

      def vacant_path
        path = path_from_name
        return path unless @options[:keep_existing] && File.exist?(path)

        2.upto(9) do |i|
          candidate = path.sub(/\.yml$/, "#{i}.yml")
          return candidate unless File.exist?(candidate)
        end

        raise Errors::GeneralError, "Formula #{path} already exists."
      end

      def path_from_name
        filename = Import.name_to_filename(name)
        if @options[:formula_dir]
          File.join(@options[:formula_dir], filename)
        else
          filename
        end
      end
    end
  end
end
