require "thor"

module Fontist
  module Utils
    class UI < Thor
      def self.say(message)
        new.say(message)
      end

      def self.ask(message, options = {})
        new.ask(message, options)
      end
    end
  end
end
