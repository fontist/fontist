module Fontist
  class CLI < Thor
    module ClassOptions
      def handle_class_options(options)
        Fontist.preferred_family = options[:preferred_family]
        Fontist.log_level = log_level(options)

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
