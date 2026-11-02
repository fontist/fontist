require "fileutils"
require "digest"
require "json"

module Fontist
  module Cache
    # Backend store persisting entries as inert JSON.
    #
    # The previous Marshal backend was removed deliberately: Marshal
    # load of a file from a user-writable path executes arbitrary
    # object instantiation on tampered content, and fontist runs
    # embedded in long-lived host processes where that escalation
    # lands. Values must be
    # JSON-native (hashes with string keys, arrays, strings, numbers,
    # booleans, nil); anything else skips the write and reads back as
    # a miss. Files written by the previous Marshal backend carry a
    # different extension and are simply never read; #clear removes
    # them.
    class Store
      FORMAT_VERSION = 1

      def initialize(cache_dir)
        @cache_dir = cache_dir.to_s
        ensure_cache_dir
      end

      def get(key)
        entry = read_entry(key)
        return nil unless entry

        if entry.expired?
          delete(key)
          return nil
        end

        entry.value
      end

      def set(key, value, ttl: nil)
        ensure_cache_dir
        entry = CacheEntry.new(value, ttl)
        write_entry(key, entry)
      rescue TypeError, JSON::GeneratorError
        # Values outside the JSON type system (Time, Date, arbitrary
        # objects) skip the write and read back as a miss
        false
      end

      def delete(key)
        File.delete(cache_path(key))
      rescue StandardError
        nil
      end

      def clear
        glob_delete("*.json")
        # Sweep entries written by the pre-JSON Marshal backend
        glob_delete("*.marshal")
      end

      def cleanup_temp_files
        # Clean up orphaned .tmp files from interrupted writes: this
        # happens when a process crashes between write and rename
        glob_delete("*.tmp")
      end

      # Cache entry with TTL support
      class CacheEntry
        attr_reader :value, :expires_at

        def initialize(value, ttl = nil, expires_at: nil)
          @value = value
          @expires_at = expires_at
          @expires_at ||= (Time.now + ttl).to_i if ttl
        end

        def expired?
          !!(@expires_at && Time.now.to_i > @expires_at)
        end
      end

      private

      attr_reader :cache_dir

      def ensure_cache_dir
        FileUtils.mkdir_p(@cache_dir)
      end

      def cache_path(key)
        File.join(@cache_dir, "#{sanitize_key(key)}.json")
      end

      def sanitize_key(key)
        key_str = key.to_s.gsub(/[^\w-]/, "_")
        # If key is too long for filesystem, hash it
        # Most filesystems have filename limits around 255 characters
        if key_str.length > 200
          "key_#{Digest::SHA256.hexdigest(key_str)[0..31]}"
        else
          key_str
        end
      end

      def glob_delete(pattern)
        Dir.glob(File.join(@cache_dir, pattern)).each do |f|
          File.delete(f)
        rescue StandardError
          nil
        end
      end

      def read_entry(key)
        return nil unless File.exist?(cache_path(key))

        payload = JSON.parse(File.read(cache_path(key)))
        CacheEntry.new(payload["value"], expires_at: payload["expires_at"])
      rescue JSON::ParserError, TypeError, EOFError
        # Corrupted file - delete it and return nil. This can happen
        # on Windows when a file is read while being written, or when
        # cache files from previous runs are corrupted
        delete(key)
        nil
      end

      def write_entry(key, entry)
        payload = entry_payload(entry)

        # Temp file + atomic rename: readers never see partial writes
        temp_path = "#{cache_path(key)}.tmp"
        File.write(temp_path, payload)
        File.rename(temp_path, cache_path(key))
      rescue StandardError => e
        # Clean up temp file if the write or rename fails
        delete(temp_path)
        raise e
      end

      def entry_payload(entry)
        JSON.dump("version" => FORMAT_VERSION,
                  "expires_at" => entry.expires_at,
                  "value" => entry.value)
      end
    end
  end
end
