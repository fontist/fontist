# frozen_string_literal: true

require_relative "formula_builder_v4"
require_relative "../../font_metadata_extractor"
require_relative "../../../utils/downloader"

module Fontist
  module Import
    module Google
      module FormulaBuilders
        # V5 formula builder for Google Fonts
        #
        # V5 supports:
        # - Multiple formats (TTF + WOFF2)
        # - Static + Variable fonts
        # - Per-file resources with format and variable_axes
        # - Per-style format metadata
        class FormulaBuilderV5 < FormulaBuilderV4
          def version
            5
          end

          def build
            license_url, license_text = build_license_info
            fonts_data = build_fonts
            copyright = extract_copyright(fonts_data)
            description = github_family&.description || default_description
            import_source = create_import_source

            formula = {
              name: formula_name,
              schema_version: 5,
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
            resources = {}

            # Check if this is a variable font (has axes)
            is_variable = family.variable_font?

            if is_variable
              # Variable fonts: the single file IS the variable font
              # Google Fonts variable fonts are WOFF2 only
              if woff2_files[family.family]&.any?
                resources["woff2_variable"] = build_resource_entry(
                  woff2_files[family.family],
                  format: "woff2",
                  variable: true,
                  axes: family.axes,
                )
              end

              # Also include TTF if available (for desktop use)
              if ttf_files[family.family]&.any?
                resources["ttf_variable"] = build_resource_entry(
                  ttf_files[family.family],
                  format: "ttf",
                  variable: true,
                  axes: family.axes,
                )
              end
            else
              # Static fonts: separate TTF and WOFF2
              static_ttf = filter_static_files(ttf_files[family.family])
              if static_ttf.any?
                resources["ttf_static"] = build_resource_entry(
                  static_ttf, format: "ttf", variable: false
                )
              end

              static_woff2 = filter_static_files(woff2_files[family.family])
              if static_woff2.any?
                resources["woff2_static"] = build_resource_entry(
                  static_woff2, format: "woff2", variable: false
                )
              end
            end

            resources
          end

          def build_resource_entry(files, format:, variable:, axes: nil)
            actual_format = detect_actual_format(files.values, format)

            entry = {
              "source" => "google",
              "family" => family.family,
              "files" => files.values,
              "urls" => files.values,
              "format" => actual_format,
            }

            entry["variable_axes"] = axes.map(&:tag) if variable && axes

            entry
          end

          def detect_actual_format(urls, declared_format)
            extensions = urls.map { |url| url.split("/").last[/\.(\w+)$/, 1]&.downcase }.compact.uniq
            if extensions.size == 1 && %w[ttf otf woff woff2].include?(extensions.first)
              extensions.first
            else
              declared_format
            end
          end

          def filter_static_files(files)
            return {} unless files

            files.reject do |variant, _|
              is_variable_variant?(variant)
            end
          end

          def is_variable_variant?(variant)
            # Variable fonts often have axes in the filename like "VariableFont_wght"
            return true if variant.include?("Variable")

            return false unless family.variable_font?

            family.axes.any? { |axis| variant.include?(axis.tag) }
          end

          def build_fonts
            parsed_fonts = []

            # V5: Download and parse ALL TTF files (including variable fonts)
            ttf_files[family.family]&.each do |variant, url|
              sleep(0.05) # Throttle API requests

              begin
                downloaded = Fontist::Utils::Downloader.download(url)
                metadata = Fontist::Import::FontMetadataExtractor.new(downloaded.path).extract

                # V5: Include both static and variable fonts
                filename = url.split("/").last

                style_data = build_style_data(metadata, filename)

                # Add v5-specific attributes
                add_v5_style_attributes(style_data, metadata, variant)

                parsed_fonts << style_data
              rescue StandardError => e
                warn "Warning: Failed to download/parse #{url}: #{e.message}"
              end
            end

            return [] if parsed_fonts.empty?

            group_fonts_by_subfamily(parsed_fonts)
          end

          def add_v5_style_attributes(style, _metadata = nil, variant = nil)
            # Add formats available for this style
            style["formats"] = determine_formats_for_style(variant)

            # Add variable font info
            # For variable fonts, ALL styles should be marked as variable
            if family.variable_font?
              style["variable_font"] = true
              style["variable_axes"] = family.axes.map(&:tag) if family.axes&.any?
            else
              style["variable_font"] = false
            end
          end

          def determine_formats_for_style(variant)
            formats = []
            formats << "ttf" if variant && ttf_files[family.family]&.key?(variant)
            formats << "woff2" if variant && woff2_files[family.family]&.key?(variant)
            formats.uniq
          end
        end
      end
    end
  end
end
