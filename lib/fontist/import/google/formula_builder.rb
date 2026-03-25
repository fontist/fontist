# frozen_string_literal: true

require_relative "formula_builders/base_formula_builder"
require_relative "formula_builders/formula_builder_v4"
require_relative "formula_builders/formula_builder_v5"

module Fontist
  module Import
    module Google
      # Factory module for creating formula builders
      module FormulaBuilder
        # Get the appropriate builder class for a version
        def self.for_version(version)
          FormulaBuilders::BaseFormulaBuilder.for_version(version)
        end

        # Build a formula using the appropriate builder for the version
        def self.build(family, version:, **kwargs)
          builder_class = for_version(version)
          builder = builder_class.new(family, **kwargs)
          builder.build
        end
      end
    end
  end
end
