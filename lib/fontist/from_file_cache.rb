module Fontist
  # Thread-safe, mtime-validated memoization for parsed YAML artifacts
  # (formula index, formula files), which cost hundreds of milliseconds to
  # parse and are re-read on every font lookup.
  #
  # Returned instances are shared between all callers and must be treated
  # as read-only. Entries re-resolve automatically when the file's mtime
  # changes (e.g. after `fontist update` rewrites the formulas repo).
  module FromFileCache
    def self.memoize(path)
      mtime = File.mtime(path)

      hit = current_value(path, mtime)
      return hit if hit

      # Parse without holding the lock so parallel readers (e.g.
      # Formula.all over worker threads) overlap; concurrent misses on
      # the same path may duplicate work but write identical values
      value = yield

      store(path, mtime, value)

      value
    end

    def self.clear
      mutex.synchronize { cache.clear }
    end

    def self.current_value(path, mtime)
      hit = mutex.synchronize { cache[path] }
      hit&.fetch(:mtime, nil) == mtime ? hit[:value] : nil
    end

    def self.store(path, mtime, value)
      mutex.synchronize do
        existing = cache[path]
        if existing.nil? || existing[:mtime] != mtime
          cache[path] = { mtime: mtime, value: value }
        end
      end
    end

    def self.mutex
      @mutex ||= Mutex.new
    end

    def self.cache
      @cache ||= {}
    end
  end
end
