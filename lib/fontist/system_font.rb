require_relative "system_index"

module Fontist
  # TODO: This is actually a SystemIndex font entry
  class SystemFont < Lutaml::Model::Serializable
    def self.font_paths
      system_font_paths + fontist_font_paths
    end

    def self.system_font_paths
      @system_font_paths ||= load_system_font_paths
    end

    # This detects all fonts on the system from the configuration file.
    def self.load_system_font_paths
      os = Fontist::Utils::System.user_os.to_s
      templates = system_config["system"][os]["paths"]
      patterns = expand_paths(templates)

      Dir.glob(patterns)
      # File::FNM_CASEFOLD is officially ignored -- see https://ruby-doc.org/core-3.1.1/Dir.html#method-c-glob
      # "Case sensitivity depends on your system"
    end

    def self.system_config
      YAML.load_file(Fontist.system_file_path)
    end

    def self.reset_system_font_paths_cache
      @system_font_paths = nil
    end

    def self.expand_paths(paths)
      paths.map do |path|
        require "etc"
        passwd = Etc.getpwuid
        username = passwd ? passwd.name : Etc.getlogin

        username ? path.gsub("{username}", username) : path
      end
    end

    def self.fontist_font_paths
      @fontist_font_paths ||= Dir.glob(Fontist.fonts_path.join("**"))
    end

    def self.reset_fontist_font_paths_cache
      @fontist_font_paths = nil
    end

    def self.reset_font_paths_cache
      reset_system_font_paths_cache
      reset_fontist_font_paths_cache
    end

    def self.find(font)
      styles = find_styles(font)
      return unless styles

      styles.map(&:path)
    end

    # This returns a SystemIndexEntry
    def self.find_styles(font, style = nil)
      SystemIndex.system_index.find(font, style)
    end
  end
end
