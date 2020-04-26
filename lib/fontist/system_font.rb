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
      font_paths.grep(/#{font}/i).first
    end

    private

    attr_reader :font, :user_sources

    def font_paths
      Dir.glob((
        user_sources +
        default_sources["paths"] +
        [Fontist.fonts_path.join("**")]
      ).flatten.uniq)
    end

    def default_sources
      @default_sources ||= Source.all.system[user_os.to_s]
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
  end
end
