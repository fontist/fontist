module Fontist
  class Finder
    def initialize(name)
      @name = name
    end

    def self.find(name)
      new(name).find
    end

    def find
      find_system_font || download_font || raise_invalid_error
    end

    private

    attr_reader :name

    def find_system_font
      Fontist::SystemFont.find(name)
    end

    def download_font
      unless remote_source.empty?
        source = remote_source_handlers[remote_source.keys.first.to_sym]
        source.fetch_font(name) if source
      end
    end

    def raise_invalid_error
      raise(Fontist::Error,"Could not find the #{name} font")
    end

    def remote_source
      @remote_source ||= sources.select do |key, value|
        value.fonts.include?(name.upcase)
      end
    end

    def sources
      Fontist::Source.all.remote.to_h
    end

    def remote_source_handlers
      @remote_source_handlers ||= { msvista: Fontist::MsVistaFont }
    end
  end
end
