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
      mutex.synchronize do
        mtime = File.mtime(path)
        entry = cache[path]
        if entry.nil? || entry[:mtime] != mtime
          entry = { mtime: mtime, value: yield }
          cache[path] = entry
        end
        entry[:value]
      end
    end

    def self.clear
      mutex.synchronize { cache.clear }
    end

    def self.mutex
      @mutex ||= Mutex.new
    end

    def self.cache
      @cache ||= {}
    end
  end
end
