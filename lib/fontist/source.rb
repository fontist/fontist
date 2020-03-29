require "yaml"

module Fontist
  class Source
    def initialize(font:, sources: nil)
      @font = font
      @user_sources = sources || []
    end

    def self.find(font, sources: [])
      new(font: font, sources: sources).find
    end

    def find
      paths = user_sources + default_sources["paths"]
      font_paths = Dir.glob(paths.flatten.uniq)

      font_path = font_paths.select do |font_path|
        break font_path if font_path.include?(font)
      end

      font_path unless font_path.empty?
    end

    private

    attr_reader :font, :user_sources

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

    def source_file
      @source_file ||= File.open(
        Fontist.lib_path.join("fontist", "data", "sources.yml"),
      )
    end

    def default_sources
      @default_sources ||= YAML.load(source_file)[user_os.to_s]
    end
  end
end
