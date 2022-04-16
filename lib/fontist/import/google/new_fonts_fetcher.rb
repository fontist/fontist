require_relative "../google"
require_relative "../otf_parser"

module Fontist
  module Import
    module Google
      class NewFontsFetcher
        REPO_PATH = Fontist.fontist_path.join("google", "fonts")
        REPO_URL = "https://github.com/google/fonts.git".freeze
        SKIPLIST_PATH = File.expand_path("skiplist.yml", __dir__)

        def initialize(logging: false)
          @logging = logging
        end

        def call
          update_repo
          fetch_new_paths
        end

        private

        def update_repo
          if Dir.exist?(REPO_PATH)
            `cd #{REPO_PATH} && git pull`
          else
            FileUtils.mkdir_p(File.dirname(REPO_PATH))
            `git clone --depth 1 #{REPO_URL} #{REPO_PATH}`
          end
        end

        def fetch_new_paths
          fetch_fonts_paths.select do |path|
            log_font(path) do
              new?(path)
            end
          end
        end

        def fetch_fonts_paths
          Dir[File.join(REPO_PATH, "apache", "*"),
              File.join(REPO_PATH, "ofl", "*"),
              File.join(REPO_PATH, "ufl", "*")].sort
        end

        def log_font(path)
          return yield unless @logging

          print "#{path}, "
          new = yield
          puts(new ? "new" : "skipped")
          new
        end

        def new?(path)
          metadata_name = Google.metadata_name(path)
          return unless metadata_name
          return if in_skiplist?(metadata_name)
          return if up_to_date?(metadata_name, path)
          return unless downloadable?(metadata_name)

          true
        end

        def in_skiplist?(name)
          @skiplist ||= YAML.safe_load(File.open(SKIPLIST_PATH))
          @skiplist.include?(name)
        end

        def up_to_date?(metadata_name, path)
          formula = formula(metadata_name)
          return false unless formula

          repo_digest_up_to_date?(formula, path) ||
            fonts_up_to_date?(formula, path)
        end

        def repo_digest_up_to_date?(formula, path)
          return unless formula.digest

          formula.digest == Google.digest(path)
        end

        def fonts_up_to_date?(formula, path)
          styles = formula_styles(formula)
          repo_fonts(path).all? do |font|
            style = styles.find { |s| s.font == repo_to_archive_name(font) }
            return false unless style

            otfinfo_version(font) == style.version
          end
        end

        def formula_styles(formula)
          formula.fonts.map(&:styles).flatten
        end

        def repo_fonts(path)
          Dir.glob(File.join(path, "*.{ttf,otf}"))
        end

        def repo_to_archive_name(font_path)
          File.basename(font_path)
            .sub("[wght]", "-VariableFont_wght")
            .sub("[opsz]", "-Regular-VariableFont_opsz")
        end

        def formula(font_name)
          path = Fontist::Import::Google.formula_path(font_name)
          Formula.new_from_file(path) if File.exist?(path)
        end

        def otfinfo_version(path)
          info = OtfParser.new(path).call
          Fontist::Import::Google.style_version(info["Version"])
        end

        def downloadable?(name)
          retries ||= 0
          retries += 1
          Down.open("https://fonts.google.com/download?family=#{name}")
          true
        rescue Down::NotFound
          false
        rescue Down::ClientError => e
          raise unless e.message == "403 Forbidden"

          false
        rescue Down::TimeoutError
          retry unless retries >= 3
          false
        end
      end
    end
  end
end
