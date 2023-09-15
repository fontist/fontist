module Fontist
  module Import
    module Google
      DEFAULT_MAX_COUNT = 100

      def self.metadata_name(path)
        metadata_path = File.join(path, "METADATA.pb")
        return unless File.exist?(metadata_path)

        File.foreach(metadata_path) do |line|
          name = line.match(/^name: "(.+)"/)
          return name[1] if name
        end
      end

      def self.formula_path(name)
        filename = name.downcase.gsub(" ", "_") + ".yml"
        Fontist.formulas_path.join("google", filename)
      end

      def self.digest(path)
        checksums = Dir.glob(File.join(path,
                             "*.{[t|T][t|T][f|F],[o|O][t|T][f|F],[t|T][t|T][c|C]}"))
          .sort
          .map { |x| Digest::SHA256.file(x).to_s }

        Digest::SHA256.hexdigest(checksums.to_s)
      end

      def self.style_version(text)
        return unless text

        text.gsub("Version ", "")
      end
    end
  end
end
