module Fontist
  module ThorExt
    # Configures Thor to behave more like a typical CLI, with better help
    # and error handling.
    #
    # - Passing -h or --help to a command will show help for that command.
    # - Unrecognized options will be treated as errors.
    # - Error messages will be printed in red to stderr, without stack trace.
    # - Full stack traces can be enabled by setting the VERBOSE env variable.
    # - Errors will cause Thor to exit with a non-zero status.
    #
    # To take advantage of this behavior, your CLI should subclass Thor
    # and extend this module.
    #
    #   class CLI < Thor
    #     extend ThorExt::Start
    #   end
    #
    # Start your CLI with:
    #
    #   CLI.start
    #
    # In tests, prevent Kernel.exit from being called when an error occurs,
    # like this:
    #
    #   CLI.start(args, exit_on_failure: false)
    #
    # - https://mattbrictson.com/blog/fixing-thor-cli-behavior
    # - https://github.com/mattbrictson/gem/blob/main/lib/example/thor_ext.rb
    module Start
      def self.extended(base)
        super
        base.check_unknown_options!
      end

      def start(given_args = ARGV, config = {})
        config[:shell] ||= Thor::Base.shell.new
        handle_help_switches(given_args) do |args|
          dispatch(nil, args, nil, config)
        end
      rescue StandardError => e
        handle_exception_on_start(e, config)
      end

      private

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def handle_help_switches(given_args)
        yield(given_args.dup)
      rescue Thor::UnknownArgumentError => e
        retry_with_args = []

        if given_args.first == "help"
          retry_with_args = ["help"] if given_args.length > 1
        elsif e.unknown.intersect?(%w[-h --help])
          retry_with_args = ["help", (given_args - e.unknown).first]
        end
        raise unless retry_with_args.any?

        yield(retry_with_args)
      end

      def handle_exception_on_start(error, config)
        return if error.is_a?(Errno::EPIPE)
        raise if ENV["VERBOSE"] || !config.fetch(:exit_on_failure, true)

        message = error.message.to_s
        if message.empty? || !error.is_a?(Thor::Error)
          message.prepend("[#{error.class}] ")
        end
        config[:shell]&.say_error(message, :red)
        exit(false)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end
  end
end
