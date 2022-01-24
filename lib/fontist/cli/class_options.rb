module Fontist
  class CLI < Thor
    module ClassOptions
      def handle_class_options(options)
        Fontist.preferred_family = options[:preferred_family]
        Fontist.log_level = options[:quiet] ? :fatal : :info

        if options[:formulas_path]
          Fontist.formulas_path = Pathname.new(options[:formulas_path])
        end
      end
    end
  end
end
