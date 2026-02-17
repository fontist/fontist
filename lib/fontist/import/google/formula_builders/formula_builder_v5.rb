# frozen_string_literal: true

require_relative "formula_builder_v4"

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

            # Static TTF (first priority for desktop)
            static_ttf = filter_static_files(ttf_files[family.family])
            if static_ttf.any?
              resources["ttf_static"] = build_resource_entry(
                static_ttf, format: "ttf", variable: false
              )
            end

            # Static WOFF2 (first priority for web)
            static_woff2 = filter_static_files(woff2_files[family.family])
            if static_woff2.any?
              resources["woff2_static"] = build_resource_entry(
                static_woff2, format: "woff2", variable: false
              )
            end

            # Variable fonts (WOFF2 only from Google)
            if family.variable_font?
              add_variable_resources(resources)
            end

            resources
          end

          def add_variable_resources(resources)
            vf_files = woff2_files[family.family]&.select do |variant, _|
              is_variable_variant?(variant)
            end

            return unless vf_files&.any?

            resources["woff2_variable"] = build_resource_entry(
              vf_files, format: "woff2", variable: true, axes: family.axes
            )
          end

          def build_resource_entry(files, format:, variable:, axes: nil)
            entry = {
              "source" => "google",
              "family" => family.family,
              "files" => files.values,
              "urls" => files.values,
              "format" => format,
            }

            entry["variable_axes"] = axes.map(&:tag) if variable && axes

            entry
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
            fonts_data = super # Reuse v4 font parsing

            # Add v5 attributes to each style
            fonts_data.each do |font|
              font["styles"].each do |style|
                add_v5_style_attributes(style)
              end
            end

            fonts_data
          end

          def add_v5_style_attributes(style)
            # Add formats available for this style
            style["formats"] = determine_formats_for_style

            # Add variable font info if applicable
            return unless family.variable_font?

            style["variable_font"] = is_variable_style?(style)
            style["variable_axes"] = family.axes.map(&:tag) if style["variable_font"]
          end

          def determine_formats_for_style
            formats = []
            formats << "ttf" if ttf_files[family.family]&.any?
            formats << "woff2" if woff2_files[family.family]&.any?
            formats.uniq
          end

          def is_variable_style?(style)
            style["font"]&.include?("Variable") ||
              style["full_name"]&.include?("Variable")
          end
        end
      end
    end
  end
end
