require "thor"

module Fontist
  module Utils
    class UI < Thor
      def self.success(message)
        new.say(message, :green)
      end

      def self.error(message)
        new.say(message, :red)
      end

      def self.say(message)
        new.say(message)
      end

      def self.ask(message, options = {})
        new.ask(message, options)
      end

      def self.print(message)
        super
      end
    end
  end
end
