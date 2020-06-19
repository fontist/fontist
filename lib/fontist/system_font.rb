module Fontist
  class SystemFont
    def initialize(font:, sources: nil)
      @font = font
      @user_sources = sources || []

      check_or_create_fontist_path
    end

    def self.find(font, sources: [])
      new(font: font, sources: sources).find
    end

    def find
      paths = font_paths.grep(/#{font}/i)
      paths = lookup_using_font_name || []  if paths.empty?

      paths.empty? ? nil : paths
    end

    private

    attr_reader :font, :user_sources

    def check_or_create_fontist_path
      unless fontist_fonts_path.exist?
        require "fileutils"
        FileUtils.mkdir_p(fontist_fonts_path)
      end
    end

    def font_paths
      Dir.glob((
        user_sources +
        default_sources["paths"] +
        [fontist_fonts_path.join("**")]
      ).flatten.uniq)
    end

    def lookup_using_font_name
      font_names = map_name_to_valid_font_names
      font_paths.grep(/#{font_names.join("|")}/i) if font_names
    end

    def fontist_fonts_path
      @fontist_fonts_path ||= Fontist.fonts_path
    end


    def user_os
      @user_os ||= (
        host_os = RbConfig::CONFIG["host_os"]
        case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :macosx
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          raise Fontist::Error, "unknown os: #{host_os.inspect}"
        end
      )
    end

    def map_name_to_valid_font_names
      fonts =  Formula.find_fonts(font)
      fonts.map { |font| font.styles.map(&:font) }.flatten if fonts
    end

    def system_path_file
      File.open(Fontist.lib_path.join("fontist", "system.yml"))
    end

    def default_sources
      @default_sources ||= YAML.load(system_path_file)["system"][user_os.to_s]
    end
  end
end
