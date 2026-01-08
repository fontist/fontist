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
      patterns = Fontist::Utils.font_file_patterns(Fontist.fonts_path.join("**").to_s)
      @fontist_font_paths ||= patterns.flat_map { |pattern| Dir.glob(pattern) }
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
      # Search across all three indexes
      results = []

      # Search fontist-managed fonts
      fontist_fonts = Fontist::Indexes::FontistIndex.instance.find(font, style)
      results.concat(fontist_fonts) if fontist_fonts

      # Search user location fonts
      user_fonts = Fontist::Indexes::UserIndex.instance.find(font, style)
      results.concat(user_fonts) if user_fonts

      # Search system fonts
      system_fonts = Fontist::Indexes::SystemIndex.instance.find(font, style)
      results.concat(system_fonts) if system_fonts

      # Remove duplicates by path and return
      return nil if results.empty?

      results.uniq { |f| f.path }
    end
  end
end
