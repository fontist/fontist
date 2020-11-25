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

    def self.find_with_style(font, style)
      new(font: font, style: style).find_with_style
    end

    def find
      paths = grep_font_paths(font)
      paths = lookup_using_font_name || []  if paths.empty?

      paths.empty? ? nil : paths
    end

    def find_with_style
      styles = Formula.find_styles_with_fonts(font, style)

      { full_name: style_full_name(styles),
        paths: style_paths(styles) }
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

    def grep_font_paths(font, style = nil)
      pattern = prepare_pattern(font, style)

      paths = font_paths.map { |path| [File.basename(path), path] }.to_h
      files = paths.keys
      matched = files.grep(pattern)
      paths.values_at(*matched).compact
    end

    def prepare_pattern(font, style = nil)
      style = nil if style&.casecmp?("regular")

      s = [font, style].compact.map { |x| Regexp.quote(x) }
        .join(".*")
        .gsub("\\ ", "\s?") # space independent

      Regexp.new(s, Regexp::IGNORECASE)
    end

    def font_paths
      @font_paths ||= Dir.glob((
        user_sources +
        normalize_default_paths +
        [fontist_fonts_path.join("**")]
      ).flatten.uniq)
    end

    def lookup_using_font_name
      font_names = map_name_to_valid_font_names || []
      font_paths.grep(/#{font_names.join("|")}/i) unless font_names.empty?
    end

    def fontist_fonts_path
      @fontist_fonts_path ||= Fontist.fonts_path
    end

    def user_os
      Fontist::Utils::System.user_os
    end

    def map_name_to_valid_font_names
      fonts =  Formula.find_fonts(font)
      fonts.map { |font| font.styles.map(&:font) }.flatten if fonts
    end

    def system_path_file
      File.open(Fontist.system_file_path)
    end

    def default_sources
      @default_sources ||= YAML.load(system_path_file)["system"][user_os.to_s]
    end

    def style_full_name(styles)
      return if styles.empty?

      s = styles.first
      s[:style]["full_name"] || s[:font]["name"]
    end

    def style_paths(styles)
      filenames = styles.map { |x| x[:style]["font"] }
      paths = lookup_using_filenames(filenames)
      return paths unless paths.empty?

      grep_font_paths(font, style)
    end

    def lookup_using_filenames(filenames)
      filenames.flat_map do |filename|
        search_font_paths(filename)
      end
    end

    def search_font_paths(filename)
      font_paths.select do |path|
        File.basename(path) == filename
      end
    end
  end
end
