module Fontist
  module Utils
    class Cache
      def fetch(key)
        map = load_cache
        return downloaded_path(map[key]) if cache_exist?(map[key])

        generated_file = yield
        path = save_cache(generated_file, key)

        downloaded_path(path)
      end

      private

      def cache_map_path
        Fontist.downloads_path.join("map.yml")
      end

      def load_cache
        cache_map_path.exist? ? YAML.load_file(cache_map_path) : {}
      end

      def downloaded_path(path)
        File.new(Fontist.downloads_path.join(path))
      end

      def cache_exist?(path)
        path && File.exist?(Fontist.downloads_path.join(path))
      end

      def save_cache(generated_file, key)
        path = move_to_downloads(generated_file)

        map = load_cache
        map[key] = path
        File.write(cache_map_path, YAML.dump(map))

        path
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
        filename = source.original_filename
        File.join(dir, filename)
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
