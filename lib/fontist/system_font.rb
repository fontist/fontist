require_relative "system_index"
require_relative "formula_paths"

module Fontist
  class SystemFont
    def initialize(font:, style: nil, sources: nil)
      @font = font
      @style = style
      @user_sources = sources || []
    end

    def self.font_paths
      system_font_paths + fontist_font_paths
    end

    def self.system_font_paths
      config_path = Fontist.system_file_path
      os = Fontist::Utils::System.user_os.to_s
      templates = YAML.load_file(config_path)["system"][os]["paths"]
      patterns = expand_paths(templates)

      Dir.glob(patterns)
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
      Dir.glob(Fontist.fonts_path.join("**"))
    end

    def self.find(font, sources: [])
      new(font: font, sources: sources).find
    end

    def self.find_styles(font, style)
      new(font: font, style: style).find_styles
    end

    def find
      styles = find_styles
      return unless styles

      styles.map { |x| x[:path] }
    end

    def find_styles
      find_by_index || find_by_formulas
    end

    private

    attr_reader :font, :style, :user_sources

    def find_by_index
      SystemIndex.new(all_paths).find(font, style)
    end

    def find_by_formulas
      FormulaPaths.new(all_paths).find(font, style)
    end

    def all_paths
      @all_paths ||= Dir.glob(user_sources) + self.class.font_paths
    end
  end
end
