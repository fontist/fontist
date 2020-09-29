module Fontist
  class SystemFont
    def initialize(font:, style: nil, sources: nil)
      @font = font
      @style = style
      @user_sources = sources || []
    end

    def self.find(font, style, sources: [])
      new(font: font, style: style, sources: sources).find
    end

    def find
      paths = []
      paths = font_paths.grep(/#{font}/i) unless @style
      paths = lookup_using_font_name || []  if paths.empty?

      paths.empty? ? nil : paths
    end

    private

    attr_reader :font, :user_sources

    def normalize_default_paths
      @normalize_default_paths ||= default_sources["paths"].map do |path|
        require "etc"
        passwd = Etc.getpwuid

        passwd ? path.gsub("{username}", passwd.name) : path
      end
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
      @user_os ||= (
        host_os = RbConfig::CONFIG["host_os"]
        case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :macos
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
      return unless fonts

      Array.new.tap do |files|
        fonts.each do |font|
          font.styles.each do |style|
            files << style.font if @style.nil? || style.type.casecmp?(@style)
          end
        end
      end
    end

    def system_path_file
      File.open(Fontist.lib_path.join("fontist", "system.yml"))
    end

    def default_sources
      @default_sources ||= YAML.load(system_path_file)["system"][user_os.to_s]
    end
  end
end
