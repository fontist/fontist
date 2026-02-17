# frozen_string_literal: true

module Fontist
  module Import
    module Google
      module FormulaBuilders
        # Base class for Google Fonts formula builders
        #
        # Subclasses implement version-specific formula generation.
        # Use FormulaBuilder.for_version(version) to get the appropriate builder.
        class BaseFormulaBuilder
          attr_reader :family, :github_index, :ttf_files, :woff2_files

          def initialize(family, github_index:, ttf_files:, woff2_files:)
            @family = family
            @github_index = github_index
            @ttf_files = ttf_files
            @woff2_files = woff2_files
          end

          # Build formula hash for the family
          # Subclasses must implement this method
          def build
            raise NotImplementedError, "Subclasses must implement #build"
          end

          # Version number for this builder
          # Subclasses must implement this method
          def version
            raise NotImplementedError, "Subclasses must implement #version"
          end

          protected

          # Common methods for all versions

          def github_family
            @github_family ||= github_index[family.family]
          end

          def formula_name
            family.family.downcase.gsub(/\s+/, "_")
          end

          def default_description
            "#{family.family} font family"
          end

          def default_homepage
            "https://fonts.google.com/specimen/#{family.family.gsub(/\s+/, '+')}"
          end

          def build_license_info
            if github_family&.license_text
              ["https://scripts.sil.org/OFL", github_family.license_text]
            else
              ["https://scripts.sil.org/OFL", "SIL Open Font License v1.1"]
            end
          end

          def create_import_source
            return nil unless family.family

            Fontist::GoogleImportSource.new(
              family: family.family,
              category: family.category,
            )
          end

          def variant_to_type(variant)
            case variant
            when "regular" then "Regular"
            when "italic" then "Italic"
            when /^(\d+)italic$/ then "#{$1} Italic"
            when /^(\d+)$/ then variant
            else variant.capitalize
            end
          end

          # Get the appropriate builder class for a version
          def self.for_version(version)
            case version
            when 4
              FormulaBuilderV4
            when 5
              FormulaBuilderV5
            else
              raise ArgumentError, "Unknown formula version: #{version}"
            end
          end
        end
      end
    end
  end
end
