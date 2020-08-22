require_relative "google/fonts_public.pb"

module Fontist
  module Import
    class GoogleCheck
      REPO_PATH = Fontist.root_path.join("tmp", "fonts")
      REPO = "https://github.com/google/fonts.git".freeze
      SKIPLIST_PATH = File.expand_path("google/skiplist.yml", __dir__)

      def call
        update_repo
        new_paths = fetch_new_paths
        indicate(new_paths)
      end

      private

      def update_repo
        if Dir.exist?(REPO_PATH)
          `cd #{REPO_PATH} && git pull`
        else
          `git clone #{REPO} #{REPO_PATH}`
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

        # Protobuf file could be downloaded from
        # https://raw.githubusercontent.com/googlefonts/gftools/master/Lib/gftools/fonts_public.proto
        #
        # To compile Protobuf to Ruby use
        # $ ruby-protoc lib/fontist/import/google/fonts_public.proto
        Google::Fonts::FamilyProto.parse_from_text(File.read(metadata_path))
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
        File.exist?(Fontist.formulas_path.join("google", formula_file(name)))
      end

      def formula_file(name)
        name.downcase.gsub(" ", "_") + "_font.rb"
      end

      def downloadable?(name)
        Down.open("https://fonts.google.com/download?family=#{name}")
        true
      rescue Down::NotFound
        false
      end

      def indicate(new_paths)
        return if new_paths.empty?

        puts "New fonts are available in:"
        new_paths.each do |path|
          puts path
        end

        abort
      end
    end
  end
end
