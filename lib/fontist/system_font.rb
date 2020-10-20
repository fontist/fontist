module Fontist
  class SystemFont
    def initialize(font:, sources: nil)
      @font = font
      @user_sources = sources || []
    end

    def self.find(font, sources: [])
      new(font: font, sources: sources).find
    end

    def find
      paths = grep_font_paths(font)
      paths = lookup_using_font_name || []  if paths.empty?

      paths.empty? ? nil : paths
    end

    private

    attr_reader :font, :user_sources

    def normalize_default_paths
      @normalize_default_paths ||= default_sources["paths"].map do |path|
        require "etc"
        passwd = Etc.getpwuid
        username = passwd ? passwd.name : Etc.getlogin

        username ? path.gsub("{username}", username) : path
      end
    end

    def grep_font_paths(font)
      paths = font_paths.map { |path| [File.basename(path), path] }.to_h
      files = paths.keys
      matched = files.grep(/#{font}/i)
      paths.values_at(*matched).compact
    end

    def font_paths
      Dir.glob((
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
  end
end
