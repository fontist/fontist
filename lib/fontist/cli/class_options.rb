module Fontist
  class CLI < Thor
    module ClassOptions
      # rubocop:disable Metrics/MethodLength
      def self.included(base)
        base.class_option :preferred_family,
                          type: :boolean,
                          desc: "Use Preferred Family when available"

        base.class_option :quiet,
                          aliases: :q,
                          type: :boolean,
                          desc: "Hide all messages"

        base.class_option :verbose,
                          aliases: :v,
                          type: :boolean,
                          desc: "Print debug messages"

        base.class_option :no_cache,
                          aliases: :c,
                          type: :boolean,
                          desc: "Avoid using cache during download"

        base.class_option :formulas_path,
                          type: :string,
                          desc: "Path to formulas"
      end
      # rubocop:enable Metrics/MethodLength

      def handle_class_options(options)
        Fontist.preferred_family = options[:preferred_family]
        Fontist.log_level = log_level(options)
        Fontist.use_cache = !options[:no_cache]

        if options[:formulas_path]
          Fontist.formulas_path = Pathname.new(options[:formulas_path])
        end
      end

      def log_level(options)
        return :debug if options[:verbose]
        return :fatal if options[:quiet]

        :info
      end
    end
  end
end
