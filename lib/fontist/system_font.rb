require_relative "system_index"

module Fontist
  class SystemFont
    def initialize(font:, style: nil, sources: nil)
      @font = font
      @style = style
      @user_sources = sources || []
    end

    def self.find(font, sources: [])
      new(font: font, sources: sources).find
    end

    def self.find_with_name(font, style)
      new(font: font, style: style).find_with_name
    end

    def find
      styles = find_styles
      return unless styles

      styles.map { |x| x[:path] }
    end

    def find_with_name
      styles = find_styles
      return { full_name: nil, paths: [] } unless styles

      { full_name: styles.first[:full_name],
        paths: styles.map { |x| x[:path] } }
    end

    private

    attr_reader :font, :style, :user_sources

    def normalize_default_paths
      @normalize_default_paths ||= default_sources["paths"].map do |path|
        require "etc"
        passwd = Etc.getpwuid
        username = passwd ? passwd.name : Etc.getlogin

        username ? path.gsub("{username}", username) : path
      end
    end

    def font_paths
      @font_paths ||= Dir.glob((
        user_sources +
        normalize_default_paths +
        [fontist_fonts_path.join("**")]
      ).flatten.uniq)
    end

    def fontist_fonts_path
      @fontist_fonts_path ||= Fontist.fonts_path
    end

    def user_os
      Fontist::Utils::System.user_os
    end

    def system_path_file
      File.open(Fontist.system_file_path)
    end

    def default_sources
      @default_sources ||= YAML.safe_load(system_path_file)["system"][user_os.to_s]
    end

    def find_styles
      find_by_index || find_by_formulas
    end

    def find_by_index
      SystemIndex.new(font_paths).find(font, style)
    end

    def find_by_formulas
      styles = find_styles_by_formulas(font, style)
      return if styles.empty?

      fonts = styles.uniq { |s| s["font"] }.flat_map do |s|
        paths = search_font_paths(s["font"])
        paths.map do |path|
          { full_name: s["full_name"],
            path: path }
        end
      end

      fonts.empty? ? nil : fonts
    end

    def find_styles_by_formulas(font, style)
      if style
        Formula.find_styles(font, style)
      else
        fonts = Formula.find_fonts(font)
        return [] unless fonts

        fonts.flat_map(&:styles)
      end
    end

    def search_font_paths(filename)
      font_paths.select do |path|
        File.basename(path) == filename
      end
    end
  end
end
