module Fontist
  module Test
    # Manages test isolation by encapsulating all stateful components
    # that need to be reset between tests.
    #
    # This class follows the Single Responsibility Principle by being
    # solely responsible for test state management.
    class IsolationManager
      # Singleton pattern - only one manager per test suite
      class << self
        def instance
          @instance ||= new
        end

        def reset!
          @instance = nil
        end
      end

      def initialize
        @managed_components = []
        register_default_components
      end

      # Reset all managed components to clean state
      def reset_all
        managed_components.each(&:reset)
      end

      # Register a component that implements #reset method
      def register_component(component)
        @managed_components << component unless @managed_components.include?(component)
      end

      private

      attr_reader :managed_components

      def register_default_components
        # Register all stateful components that need cleanup
        register_component(SystemIndexComponent.new)
        register_component(SystemFontComponent.new)
        register_component(FormulaIndexComponent.new)
      end
    end

    # Component pattern - each component knows how to reset its own state
    class SystemIndexComponent
      def reset
        # Reset SystemIndex class-level caches
        Fontist::SystemIndex.reset_cache

        # Reset verification flags on any cached instances
        reset_cached_instances
      end

      private

      def reset_cached_instances
        %i[@system_index @fontist_index].each do |ivar|
          next unless Fontist::SystemIndex.instance_variable_defined?(ivar)

          index = Fontist::SystemIndex.instance_variable_get(ivar)
          index&.reset_verification! if index.respond_to?(:reset_verification!)
        end
      end
    end

    class SystemFontComponent
      def reset
        Fontist::SystemFont.reset_font_paths_cache
      end
    end

    class FormulaIndexComponent
      def reset
        Fontist::Index.reset_cache
      end
    end
  end
end
