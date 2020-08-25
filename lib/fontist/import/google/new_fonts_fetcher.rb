require_relative "fonts_public.pb"
require_relative "../google"

module Fontist
  module Import
    module Google
      class NewFontsFetcher
        REPO_PATH = Fontist.root_path.join("tmp", "fonts")
        REPO_URL = "https://github.com/google/fonts.git".freeze
        SKIPLIST_PATH = File.expand_path("skiplist.yml", __dir__)

        def call
          update_repo
          fetch_new_paths.sort
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
            new?(path)
          end
        end

        def fetch_fonts_paths
          Dir[File.join(REPO_PATH, "apache", "*"),
              File.join(REPO_PATH, "ofl", "*"),
              File.join(REPO_PATH, "ufl", "*")]
        end

        def new?(path)
          metadata = fetch_metadata(path)
          return unless metadata

          font_new?(metadata)
        end

        def fetch_metadata(path)
          metadata_path = File.join(path, "METADATA.pb")
          return unless File.exists?(metadata_path)

          ::Google::Fonts::FamilyProto.parse_from_text(File.read(metadata_path))
        end

        def font_new?(metadata)
          return if in_skiplist?(metadata.name)
          return if formula_exists?(metadata.name)
          return unless downloadable?(metadata.name)

          true
        end

        def in_skiplist?(name)
          @skiplist ||= YAML.safe_load(File.open(SKIPLIST_PATH))
          @skiplist.include?(name)
        end

        def formula_exists?(name)
          File.exist?(Fontist::Import::Google.formula_path(name))
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
