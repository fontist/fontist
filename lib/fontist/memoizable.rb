module Fontist
  module Memoizable
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Instance methods for memoization support
    def generate_memo_cache_key(method_name, args, key_proc)
      if key_proc
        key_proc.call(*args)
      else
        "#{method_name}:#{args.hash}"
      end
    end

    def memo_cache_expired?(_cached)
      # Cache::Manager handles TTL internally
      false
    end

    def clear_memo_cache
      # Clear all tracked cache keys from disk and memory
      @memo_cache_keys&.each do |key|
        Fontist::Cache::Manager.delete(key)
      end
      @memo_cache = {}
      @memo_cache_keys = Set.new
    end

    module ClassMethods
      # Declare memoized methods with cache backing
      # Example: memoize :method_name, ttl: 300, key: -> { "cache_key" }
      def memoize(method_name, ttl: nil, key: nil)
        original_method = "_unmemoized_#{method_name}"
        alias_method original_method, method_name

        define_method(method_name) do |*args|
          cache_key = generate_memo_cache_key(method_name, args, key)

          # Try memory cache first (fastest)
          @memo_cache ||= {}
          @memo_cache_keys ||= Set.new

          if @memo_cache[cache_key]
            return @memo_cache[cache_key]
          end

          # Try disk cache (persistent across runs)
          cached = Fontist::Cache::Manager.get(cache_key)
          if cached && !memo_cache_expired?(cached)
            @memo_cache[cache_key] = cached
            @memo_cache_keys.add(cache_key)
            return cached
          end

          # Compute and cache
          result = send(original_method, *args)
          @memo_cache[cache_key] = result
          @memo_cache_keys.add(cache_key)
          Fontist::Cache::Manager.set(cache_key, result, ttl: ttl) if ttl

          result
        end
      end
    end
  end
end
