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

            # The only genuine variable files are the ones in google/fonts.
            # The API serves static per-weight instances for every family,
            # including variable ones, so those always go to *_static.
            if variable_source
              resources["ttf_variable"] =
                variable_source.resource(family.family)
            end

            resources.merge(static_resources)
          end

          def static_resources
            static_resource("ttf_static", "ttf", ttf_files)
              .merge(static_resource("woff2_static", "woff2", woff2_files))
          end

          def static_resource(key, format, files_by_family)
            files = filter_static_files(files_by_family[family.family])
            return {} if files.empty?

            { key => build_resource_entry(files, format: format,
                                                 variable: false) }
          end

          def variable_source
            github_family&.variable_source
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
            extensions = urls.filter_map do |url|
              url.split("/").last[/\.(\w+)$/, 1]&.downcase
            end.uniq
            if extensions.size == 1 && %w[ttf otf woff
                                          woff2].include?(extensions.first)
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
            variant.include?("Variable")
          end

          def build_fonts
            parsed_fonts = []

            # V5: Download and parse the API's static TTF files
            ttf_files[family.family]&.each do |variant, url|
              sleep(0.05) # Throttle API requests

              begin
                downloaded = Fontist::Utils::Downloader.download(url)
                metadata = Fontist::Import::FontMetadataExtractor.new(downloaded.path).extract

                filename = url.split("/").last

                style_data = build_style_data(metadata, filename)

                # Add v5-specific attributes
                add_v5_style_attributes(style_data, metadata, variant)

                parsed_fonts << style_data
              rescue StandardError => e
                warn "Warning: Failed to download/parse #{url}: #{e.message}"
              end
            end

            parsed_fonts.concat(variable_source.styles) if variable_source
            return [] if parsed_fonts.empty?

            group_fonts_by_subfamily(parsed_fonts)
          end

          def add_v5_style_attributes(style, _metadata = nil, variant = nil)
            # Add formats available for this style
            style["formats"] = determine_formats_for_style(variant)

            # Styles built from API files are static instances; the real
            # variable styles come from variable_source.
            style["variable_font"] = false
            style["source_resource"] = "ttf_static" if variable_source
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
