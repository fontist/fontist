require_relative "store"

module Fontist
  module Cache
    # Central cache manager for font index caching operations
    class Manager
      @stores = {}
      @cache_dir = nil

      class << self
        # Cache directory is determined lazily to avoid initialization issues
        def cache_dir
          @cache_dir ||= Fontist.root_path.join("cache")
        end

        # Public API for cache operations
        def get(key, namespace: nil)
          store(namespace).get(key)
        end

        def set(key, value, ttl: nil, namespace: nil)
          store(namespace).set(key, value, ttl: ttl)
        end

        def delete(key, namespace: nil)
          store(namespace).delete(key)
        end

        def clear(namespace: nil)
          return clear_all unless namespace

          store(namespace).clear
        end

        # Convenience methods for directory-level caching
        def get_directory_fonts(directory_path)
          get("directory:#{directory_path}", namespace: :indexes)
        end

        def set_directory_fonts(directory_path, fonts)
          set("directory:#{directory_path}", fonts, ttl: 3600, namespace: :indexes)
        end

        private

        def store(namespace)
          @stores ||= {}
          @stores[namespace ||= :default] ||= Store.new(cache_dir.join(namespace.to_s))
        end

        def clear_all
          Dir.glob(cache_dir.join("*")).each do |path|
            next if path == "." || path == ".."
            FileUtils.rm_rf(path) rescue nil
          end
        end
      end
    end
  end
end
