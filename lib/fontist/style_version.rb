module Fontist
  class StyleVersion
    def initialize(text)
      @text = text
    end

    def to_s
      value.join(" . ")
    end

    def value
      @value ||= numbers || default_value
    end

    def numbers
      string_version&.split(".")&.map(&:strip)
    end

    def string_version
      @text&.split(";")&.first
    end

    def default_value
      ["0"]
    end

    def <=>(other)
      value <=> other.value
    end

    def ==(other)
      value == other.value
    end

    def eql?(other)
      value.eql?(other.value)
    end

    def hash
      value.hash
    end
  end
end
