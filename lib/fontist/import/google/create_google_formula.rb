require "fontist/import"
require "fontist/import/formula_builder"
require "fontist/import/otf/font_file"

module Fontist
  module Import
    module Google
      class CreateGoogleFormula
        REPO_PATH = Fontist.fontist_path.join("google", "fonts")
        POSSIBLE_LICENSE_FILES = ["LICENSE.txt",
                                  "LICENCE.txt",
                                  "OFL.txt",
                                  "UFL.txt"].freeze

        def initialize(item, options = {})
          @item = item
          @options = options
        end

        def call
          builder = FormulaBuilder.new
          builder.options = options
          builder.resources = resources
          builder.font_files = font_files
          builder.license_text = license_text
          builder.save
        end

        private

        def options
          @options.merge(name: formula_name, open_license: true)
        end

        def formula_name
          @item["family"]
        end

        def resources
          {
            @item["family"] => {
              source: "google",
              family: @item["family"],
              files: @item["files"].values,
            },
          }
        end

        def font_files
          @font_files ||= @item["files"].map do |_key, url|
            font_file(url)
          end
        end

        def license_text
          @license_text ||= find_license_text
        end

        def font_file(url)
          path = Utils::Downloader.download(url, use_content_length: false).path
          Otf::FontFile.new(path)
        end

        def find_license_text
          file = license_file
          return unless file

          File.read(file)
        end

        def license_file
          dir = @item["family"].gsub(" ", "").downcase
          path = repo_paths(dir).first
          return unless path

          full_paths = POSSIBLE_LICENSE_FILES.map { |f| File.join(path, f) }

          Dir[*full_paths].first
        end

        def repo_paths(dir)
          Dir[File.join(REPO_PATH, "apache", dir),
              File.join(REPO_PATH, "ofl", dir),
              File.join(REPO_PATH, "ufl", dir)]
        end
      end
    end
  end
end
