# frozen_string_literal: true

require_relative "base_formula_builder"
require_relative "../../../utils/downloader"
require_relative "../../../font_metadata_extractor"

module Fontist
  module Import
    module Google
      module FormulaBuilders
        # V4 formula builder for Google Fonts
        #
        # V4 Requirements:
        # - TTF format ONLY (no WOFF2)
        # - Static fonts ONLY (exclude variable fonts)
        # - OFL.txt license from GitHub repository
        # - Complete metadata from Fontisan
        class FormulaBuilderV4 < BaseFormulaBuilder
          def version
            4
          end

          def build
            license_url, license_text = build_license_info
            fonts_data = build_fonts
            copyright = extract_copyright(fonts_data)
            description = github_family&.description || default_description
            import_source = create_import_source

            formula = {
              name: formula_name,
              description: description,
              homepage: default_homepage,
              resources: build_resources,
              fonts: fonts_data,
              extract: {},
              copyright: copyright,
              license_url: license_url,
              license: license_text,
              open_license: license_text,
            }

            formula[:import_source] = import_source if import_source
            formula.compact
          end

          private

          def build_resources
            files = []

            # V4: Collect ONLY TTF URLs from API (no WOFF2)
            ttf_files[family.family]&.each_value do |url|
              files << url
            end

            return nil if files.empty?

            # V4: Always use "ttf" format (no variable fonts in v4)
            resource = {
              "source" => "google",
              "family" => family.family,
              "files" => files,
              "format" => "ttf",
            }

            # Add variable_axes if present
            if family.variable_font? && family.axes
              resource["variable_axes"] = family.axes.map(&:tag)
            end

            { family.family => resource }
          end

          def build_fonts
            parsed_fonts = []

            # V4: Download and parse ONLY TTF files to get complete metadata
            ttf_files[family.family]&.each_value do |url|
              sleep(0.05) # Throttle API requests

              begin
                downloaded = Fontist::Utils::Downloader.download(url)
                metadata = Fontist::Import::FontMetadataExtractor.new(downloaded.path).extract

                # V4: Skip variable fonts
                next if metadata.is_variable

                filename = url.split("/").last

                style_data = build_style_data(metadata, filename)
                parsed_fonts << style_data
              rescue StandardError => e
                warn "Warning: Failed to download/parse #{url}: #{e.message}"
              end
            end

            return [] if parsed_fonts.empty?

            group_fonts_by_subfamily(parsed_fonts)
          end

          def build_style_data(metadata, filename)
            style_data = {
              family_name: metadata.family_name,
              type: metadata.subfamily_name,
              full_name: metadata.full_name,
              post_script_name: metadata.postscript_name,
              version: metadata.version,
              copyright: metadata.copyright,
              font: filename,
            }

            style_data[:preferred_family_name] = metadata.preferred_family_name if metadata.preferred_family_name
            style_data[:preferred_type] = metadata.preferred_subfamily_name if metadata.preferred_subfamily_name
            style_data[:description] = metadata.description if metadata.description

            style_data
          end

          def group_fonts_by_subfamily(fonts)
            fonts_by_subfamily = fonts.group_by { |f| f[:family_name] }

            fonts_by_subfamily.map do |subfamily_name, styles|
              {
                "name" => subfamily_name,
                "styles" => styles.map { |s| stringify_style(s) },
              }
            end
          end

          def stringify_style(style)
            style.transform_keys(&:to_s).transform_values do |v|
              v.is_a?(Symbol) ? v.to_s : v
            end
          end

          def extract_copyright(fonts_data)
            fonts_data.dig(0, "styles", 0, "copyright") || github_family&.license_text
          end
        end
      end
    end
  end
end
