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
        register_component(ConfigComponent.new)
        register_component(SystemComponent.new)
        # NOTE: TempDirectoryComponent removed - aggressive cleanup before tests
        # causes issues on Windows where tempfiles need to be kept alive
        # to prevent GC/EACCES errors. Tests use temp directories that are
        # automatically cleaned up by Ruby's tempfile lifecycle.
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

    class ConfigComponent
      def reset
        Fontist::Config.reset
      end
    end

    class SystemComponent
      def reset
        Fontist::Utils::System.reset_cache
      end
    end

    class TempDirectoryComponent
      def reset
        # Clean up any fontist temp directories that might be left behind
        # This helps prevent test pollution on Windows where temp directories
        # might not be cleaned up properly by Dir.mktmpdir
        cleanup_fontist_temp_dirs
        cleanup_fontist_lock_files if windows?
      end

      private

      def cleanup_fontist_temp_dirs
        # Find and remove any fontist temp directories
        temp_base = Dir.tmpdir
        fontist_dirs = Dir.glob(File.join(temp_base, "fontist*"))

        fontist_dirs.each do |dir|
          begin
            FileUtils.remove_entry(dir) if File.directory?(dir)
          rescue => e
            # Log but don't fail - cleanup is best effort
            warn "Warning: Could not remove temp directory #{dir}: #{e.message}"
          end
        end
      end

      def cleanup_fontist_lock_files
        # On Windows, also clean up potential lock files in temp directory
        # that might prevent directory removal
        temp_base = Dir.tmpdir
        lock_files = Dir.glob(File.join(temp_base, "*lock*")) +
                    Dir.glob(File.join(temp_base, "*fontist*.tmp"))

        lock_files.each do |file|
          begin
            FileUtils.remove_entry(file) if File.exist?(file)
          rescue => e
            # Log but don't fail - cleanup is best effort
            warn "Warning: Could not remove lock file #{file}: #{e.message}"
          end
        end
      end

      def windows?
        # Check if we're on Windows without caching the result
        # UseRbConfig::CONFIG to avoid caching
        host_os = RbConfig::CONFIG["host_os"]
        host_os =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      end
    end
  end
end
