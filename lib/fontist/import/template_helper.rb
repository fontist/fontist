module Fontist
  module Import
    module TemplateHelper
      class << self
        def bind(resource, name = nil)
          b = binding
          b.local_variable_set(name, resource) if name
          b
        end

        def escape_double_quotes(text)
          text.gsub('"', '\"')
        end

        alias esc escape_double_quotes
      end
    end
  end
end
