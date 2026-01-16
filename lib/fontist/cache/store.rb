require "fileutils"
require "digest"

module Fontist
  module Cache
    # Backend store using Marshal for serialization
    class Store
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
      end

      def delete(key)
        File.delete(cache_path(key))
      rescue StandardError
        nil
      end

      def clear
        Dir.glob(File.join(@cache_dir, "*.marshal")).each do |f|
          File.delete(f)
        rescue StandardError
          nil
        end
      end

      private

      attr_reader :cache_dir

      def ensure_cache_dir
        FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
      end

      def cache_path(key)
        File.join(@cache_dir, "#{sanitize_key(key)}.marshal")
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

      def read_entry(key)
        return nil unless File.exist?(cache_path(key))

        Marshal.load(File.read(cache_path(key)))
      end

      def write_entry(key, entry)
        File.write(cache_path(key), Marshal.dump(entry))
      end

      # Cache entry with TTL support
      class CacheEntry
        attr_reader :value, :expires_at

        def initialize(value, ttl)
          @value = value
          @expires_at = ttl ? (Time.now + ttl).to_i : nil
        end

        def expired?
          !!(@expires_at && Time.now.to_i > @expires_at)
        end
      end
    end
  end
end
