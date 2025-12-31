require "shellwords"
require_relative "text_helper"
require_relative "helpers/hash_helper"
require_relative "../macos_import_source"
require_relative "../google_import_source"
require_relative "../sil_import_source"

module Fontist
  module Import
    class FormulaBuilder
      FORMULA_ATTRIBUTES = %i[name platforms description homepage resources
                              font_collections fonts extract copyright
                              license_url requires_license_agreement
                              open_license digest command
                              import_source font_version].freeze

      attr_writer :resources,
                  :options,
                  :font_files,
                  :font_collection_files,
                  :license_text,
                  :operations,
                  :font_version,
                  :import_source

      def initialize
        @options = {}
        @font_files = []
        @font_collection_files = []
      end

      def formula
        formula_attributes.to_h { |name| [name, send(name)] }.compact
      end

      def save
        path = path_from_name

        # Honor keep_existing option - don't overwrite if file exists and keep_existing is true
        if @options[:keep_existing] && File.exist?(path)
          return path
        end

        yaml = YAML.dump(Helpers::HashHelper.stringify_keys(formula))
        File.write(path, yaml)
        path
      end

      def import_source
        @import_source
      end

      def font_version
        @font_version
      end

      # Convenience method to set macOS import source
      def set_macos_import_source(framework_version:, posted_date:, asset_id:)
        @import_source = MacosImportSource.new(
          type: "macos",
          framework_version: framework_version,
          posted_date: posted_date,
          asset_id: asset_id
        )
      end

      # Convenience method to set Google import source
      def set_google_import_source(commit_id:, api_version:, last_modified:, family_id:)
        @import_source = GoogleImportSource.new(
          type: "google",
          commit_id: commit_id,
          api_version: api_version,
          last_modified: last_modified,
          family_id: family_id
        )
      end

      # Convenience method to set SIL import source
      def set_sil_import_source(version:, release_date:)
        @import_source = SilImportSource.new(
          type: "sil",
          version: version,
          release_date: release_date
        )
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
        if files.empty?
          raise Errors::FontNotFoundError,
                "No fonts found in archive. This may be due to:\n" \
                "  - Archive contains only TTC files that fontisan cannot parse\n" \
                "  - Archive is empty or corrupted\n" \
                "  - Fonts are in unsupported format"
        end

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
        files.map(&style_type).map { |style| deep_compact(style) }.sort_by { |x| x[:type] }
      end

      # Recursively remove nil values from hashes and arrays
      def deep_compact(value)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), result|
            compacted = deep_compact(v)
            result[k] = compacted unless compacted.nil?
          end
        when Array
          value.map { |item| deep_compact(item) }.compact
        else
          value
        end
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

      def path_from_name
        filename = generate_filename
        if @options[:formula_dir]
          File.join(@options[:formula_dir], filename)
        else
          filename
        end
      end

      # Generate filename with versioning support
      #
      # For import sources with differentiation_key (like SIL with versions),
      # generates versioned filenames: name_version.yml
      # For others, generates simple filenames: name.yml
      def generate_filename
        base_name = Fontist::Import.normalize_filename(name)

        # Add differentiation_key if import_source supports it
        if @import_source&.respond_to?(:differentiation_key) &&
           (key = @import_source.differentiation_key)
          "#{base_name}_#{key}.yml"
        else
          "#{base_name}.yml"
        end
      end
    end
  end
end