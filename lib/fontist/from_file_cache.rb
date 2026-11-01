module Fontist
  # Thread-safe, mtime-validated memoization for parsed YAML artifacts
  # (formula index, formula files), which cost hundreds of milliseconds
  # to parse and are re-read on every font lookup.
  #
  # Retention is bounded: fontist runs embedded in long-lived host
  # processes (metanorma compiles) under memory caps, so the cache is
  # an LRU holding at most max_entries parsed documents instead of
  # every file the process has ever touched (~350MB for a full
  # formulas corpus). Returned instances are shared between callers
  # and must be treated as read-only. Entries re-resolve automatically
  # when the file's mtime changes (e.g. after `fontist update`
  # rewrites the formulas repo).
  module FromFileCache
    DEFAULT_MAX_ENTRIES = 64

    class << self
      attr_writer :max_entries

      def max_entries
        @max_entries ||= DEFAULT_MAX_ENTRIES
      end

      def memoize(path)
        mtime = File.mtime(path)

        hit = mutex.synchronize { lookup(path, mtime) }
        return hit if hit

        # Parse without holding the lock so parallel readers (e.g.
        # Formula.all over worker threads) overlap; concurrent misses on
        # the same path may duplicate work but write identical values
        value = yield

        store(path, mtime, value)

        value
      end

      def clear
        mutex.synchronize { cache.clear }
      end

      private

      attr_reader :mutex

      def mutex
        @mutex ||= Mutex.new
      end

      def cache
        @cache ||= {}
      end

      def lookup(path, mtime)
        entry = cache[path]
        return nil unless entry&.fetch(:mtime, nil) == mtime

        cache.delete(path)
        cache[path] = entry

        entry[:value]
      end

      def store(path, mtime, value)
        mutex.synchronize do
          existing = cache[path]
          return if existing&.fetch(:mtime, nil) == mtime

          cache.delete(path)
          cache.delete(cache.each_key.first) if cache.size >= max_entries
          cache[path] = { mtime: mtime, value: value }
        end
      end
    end
  end
end
