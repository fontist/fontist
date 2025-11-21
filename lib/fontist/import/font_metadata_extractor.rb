require "fontisan"
require_relative "models/font_metadata"

module Fontist
  module Import
    class FontMetadataExtractor
      def initialize(path)
        @path = path
      end

      def extract
        font_info = Fontisan::Commands::InfoCommand.new(@path, {}).run
        build_metadata(font_info)
      rescue StandardError => e
        raise Errors::FontExtractError,
              "Failed to extract metadata from #{@path}: #{e.message}"
      end

      private

      def build_metadata(font_info)
        Models::FontMetadata.new(
          family_name: safe_get(font_info, :family_name),
          subfamily_name: safe_get(font_info, :subfamily_name),
          full_name: safe_get(font_info, :full_name),
          postscript_name: safe_get(font_info, :postscript_name),
          preferred_family_name: safe_get(font_info, :preferred_family_name),
          preferred_subfamily_name: safe_get(font_info, :preferred_subfamily_name),
          version: clean_version(safe_get(font_info, :version)),
          copyright: safe_get(font_info, :copyright),
          description: safe_get(font_info, :license_description),
          vendor_url: safe_get(font_info, :vendor_url),
          license_url: safe_get(font_info, :license_url),
          font_format: safe_get(font_info, :font_format),
          is_variable: safe_get(font_info, :is_variable)
        )
      end

      def safe_get(object, method)
        object.respond_to?(method) ? object.send(method) : nil
      end

      def clean_version(version)
        return nil unless version

        version.to_s.gsub(/^Version\s+/i, "")
      end
    end
  end
end