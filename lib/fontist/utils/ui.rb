require "thor"

module Fontist
  module Utils
    class UI < Thor
      ALL_LEVELS = %i[debug info warn error fatal unknown].freeze

      def self.level=(level)
        unless ALL_LEVELS.include?(level)
          raise Errors::GeneralError,
                "Unknown log level: #{level.inspect}. " \
                "Supported levels are #{ALL_LEVELS.map(&:inspect).join(', ')}."
        end

        @level = level
      end

      def self.level
        @level || default_level
      end

      def self.default_level
        :fatal
      end

      def self.success(message)
        new.say(message, :green) if log_levels.include?(:info)
      end

      def self.error(message)
        new.say(message, :red) if log_levels.include?(:warn)
      end

      def self.say(message)
        new.say(message) if log_levels.include?(:info)
      end

      def self.ask(message, options = {})
        new.ask(message, options)
      end

      def self.print(message)
        super if log_levels.include?(:info)
      end

      def self.debug(message)
        new.say(message) if log_levels.include?(:debug)
      end

      def self.log_levels
        @log_levels ||= {}
        @log_levels[@level] ||= ALL_LEVELS.drop_while { |l| l != level }
      end
    end
  end
end
