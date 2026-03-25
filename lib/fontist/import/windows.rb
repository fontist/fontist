require "yaml"
require "fileutils"

module Fontist
  module Import
    class Windows
      HOMEPAGE = "https://learn.microsoft.com/en-us/typography/fonts/windows_11_font_list".freeze

      def initialize(formulas_dir: nil)
        @custom_formulas_dir = formulas_dir
      end

      def call
        capabilities = WindowsFodMetadata.all_capabilities

        Fontist.ui.say("Generating #{capabilities.size} Windows FOD formula files...")

        capabilities.each do |cap_name|
          generate_formula(cap_name)
        end

        Fontist.ui.say("Done. #{capabilities.size} formulas generated.")
      end

      private

      def generate_formula(cap_name)
        description = WindowsFodMetadata.description_for_capability(cap_name)
        fonts_data = WindowsFodMetadata.fonts_for_capability(cap_name)

        formula = build_formula(cap_name, description, fonts_data)

        path = formula_path(description)
        FileUtils.mkdir_p(File.dirname(path))

        yaml = YAML.dump(stringify_keys(formula))
        File.write(path, yaml)

        Fontist.ui.say("  Created: #{File.basename(path)} (#{fonts_data.size} font families)")
      end

      def build_formula(cap_name, description, fonts_data)
        {
          schema_version: 5,
          name: description,
          description: "#{description} for Windows",
          homepage: HOMEPAGE,
          platforms: ["windows"],
          resources: build_resources(cap_name, description, fonts_data),
          fonts: build_fonts(fonts_data),
          open_license: license_text,
          import_source: {
            type: "windows",
            capability_name: cap_name,
            min_windows_version: "10.0",
          },
        }
      end

      def build_resources(cap_name, description, fonts_data)
        all_fonts = fonts_data.flat_map { |_, data| data["styles"].map { |s| s["font"] } }
        formats = all_fonts.map { |f| detect_format(f) }.uniq

        resource = {
          source: "windows_fod",
          capability_name: cap_name,
        }
        resource[:format] = formats.first if formats.size == 1

        { normalize_key(description) => resource }
      end

      def build_fonts(fonts_data)
        fonts_data.map do |family_name, data|
          {
            name: family_name,
            styles: data["styles"].map do |style|
              fmt = detect_format(style["font"])
              {
                family_name: family_name,
                type: style["type"],
                font: style["font"],
                formats: [fmt],
                variable_font: false,
              }
            end,
          }
        end
      end

      def detect_format(filename)
        File.extname(filename).downcase.delete(".").then do |ext|
          %w[ttf ttc otf otc].include?(ext) ? ext : "ttf"
        end
      end

      def formula_path(description)
        filename = normalize_key(description) + ".yml"
        formula_dir.join(filename)
      end

      def formula_dir
        @formula_dir ||= if @custom_formulas_dir
                           Pathname.new(@custom_formulas_dir).tap do |path|
                             FileUtils.mkdir_p(path)
                           end
                         else
                           Fontist.formulas_path.join("windows").tap do |path|
                             FileUtils.mkdir_p(path)
                           end
                         end
      end

      def normalize_key(name)
        name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
      end

      def license_text
        @license_text ||= File.read(
          File.expand_path("windows/windows_license.txt", __dir__),
        )
      end

      # Recursively stringify hash keys for YAML output
      def stringify_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), result|
            result[k.to_s] = stringify_keys(v)
          end
        when Array
          obj.map { |item| stringify_keys(item) }
        else
          obj
        end
      end
    end
  end
end
