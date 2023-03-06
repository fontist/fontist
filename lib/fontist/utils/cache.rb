module Fontist
  module Utils
    class Cache
      include Locking

      def self.lock_path(path)
        "#{path}.lock"
      end

      def fetch(key)
        map = load_cache
        if cache_exist?(map[key])
          print(map[key])

          return downloaded_file(map[key])
        end

        generated_file = yield
        path = save_cache(generated_file, key)

        downloaded_file(path)
      end

      def delete(key)
        lock(lock_path) do
          map = load_cache
          return unless map[key]

          value = map.delete(key)
          File.write(cache_map_path, YAML.dump(map))
          value
        end
      end

      def set(key, value)
        lock(lock_path) do
          map = load_cache
          map[key] = value
          File.write(cache_map_path, YAML.dump(map))
        end
      end

      private

      def cache_map_path
        Fontist.downloads_path.join("map.yml")
      end

      def load_cache
        cache_map_path.exist? ? YAML.load_file(cache_map_path) : {}
      end

      def downloaded_file(path)
        File.new(downloaded_path(path), "rb")
      end

      def cache_exist?(path)
        path && File.exist?(downloaded_path(path))
      end

      def downloaded_path(path)
        Fontist.downloads_path.join(path)
      end

      def print(path)
        Fontist.ui.say("Fetched from cache: #{size(path)} MiB.")
      end

      def size(path)
        File.size(downloaded_path(path)) / (1024 * 1024)
      end

      def save_cache(generated_file, key)
        path = move_to_downloads(generated_file)

        lock(lock_path) do
          map = load_cache
          map[key] = path
          File.write(cache_map_path, YAML.dump(map))
        end

        path
      end

      def lock_path
        Cache.lock_path(cache_map_path)
      end

      def move_to_downloads(source)
        create_downloads_directory
        path = generate_file_path(source)
        move(source, path)
        relative_to_downloads(path)
      end

      def create_downloads_directory
        unless Fontist.downloads_path.exist?
          FileUtils.mkdir_p(Fontist.downloads_path)
        end
      end

      def generate_file_path(source)
        dir = Dir.mktmpdir(nil, Fontist.downloads_path)
        File.join(dir, filename(source))
      end

      def filename(source)
        if File.extname(source.original_filename).empty? && source.content_type
          require "mime/types"
          ext = MIME::Types[source.content_type].first&.preferred_extension
          return "#{source.original_filename}.#{ext}" if ext
        end

        source.original_filename
      end

      def move(source_file, target_path)
        # Windows requires file descriptors to be closed before files are moved
        source_file.close
        FileUtils.mv(source_file.path, target_path)
      end

      def relative_to_downloads(path)
        Pathname.new(path).relative_path_from(Fontist.downloads_path).to_s
      end
    end
  end
end
