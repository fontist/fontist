require_relative "fonts_public.pb"
require_relative "../google"
require_relative "../otf_parser"

module Fontist
  module Import
    module Google
      class NewFontsFetcher
        REPO_PATH = Fontist.root_path.join("tmp", "fonts")
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
            `git clone #{REPO_URL} #{REPO_PATH}`
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
          metadata = fetch_metadata(path)
          return unless metadata

          font_new?(metadata, path)
        end

        def fetch_metadata(path)
          metadata_path = File.join(path, "METADATA.pb")
          return unless File.exists?(metadata_path)

          ::Google::Fonts::FamilyProto.parse_from_text(File.read(metadata_path))
        end

        def font_new?(metadata, path)
          return if in_skiplist?(metadata.name)
          return if up_to_date?(metadata, path)
          return unless downloadable?(metadata.name)

          true
        end

        def in_skiplist?(name)
          @skiplist ||= YAML.safe_load(File.open(SKIPLIST_PATH))
          @skiplist.include?(name)
        end

        def up_to_date?(metadata, path)
          formula = formula(metadata.name)
          return false unless formula

          styles = formula.fonts.map(&:styles).flatten

          styles.all? do |style|
            style.version == otfinfo_version(font_path(style.font, path))
          end
        end

        def formula(font_name)
          klass = font_name.gsub(/ /, "").sub(/\S/, &:upcase)
          Fontist::Formula.all["Fontist::Formulas::#{klass}Font"]
        end

        def font_path(filename, directory)
          File.join(directory, fix_variable_filename(filename))
        end

        def fix_variable_filename(filename)
          filename.sub("-VariableFont_wght", "[wght]")
        end

        def otfinfo_version(path)
          info = OtfParser.new(path).call
          Fontist::Import::Google.style_version(info["Version"])
        end

        def downloadable?(name)
          Down.open("https://fonts.google.com/download?family=#{name}")
          true
        rescue Down::NotFound
          false
        end
      end
    end
  end
end
