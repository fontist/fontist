module Fontist
  class Finder
    def initialize(name, path:)
      @name = name
      @path = path
    end

    def copy
      font = find_font

      copy_to(font, path) || raise(
        Fontist::Error, "Could not find #{name} font"
      )
    end

    def self.copy(name, path)
      new(name, path: path).copy
    end

    private

    attr_reader :name, :path

    def find_font
      Fontist::Source.find(name)
    end

    def copy_to(font, path)
      if font
        unless File.writable?(path)
          raise(Fontist::Error, "No such writable file or directory")
        end

        FileUtils.cp(font, path)
        Pathname.new(path).join(name).to_s
      end
    end
  end
end
