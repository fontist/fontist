require "lutaml/model"
require "marcel"

module Fontist
  module Utils
    class CacheIndexItem < Lutaml::Model::Serializable
      attribute :url, :string
      attribute :name, :string
    end

    class CacheIndex < Lutaml::Model::Serializable
      attribute :items, CacheIndexItem, collection: true, default: []

      key_value do
        map to: :items, root_mappings: {
          url: :key,
          name: :value,
        }
      end

      def self.from_file(path)
        return new unless File.exist?(path)

        content = File.read(path)

        return new if content.strip.empty? || content.strip == "---"

        from_yaml(content) || {}
      end

      def to_file(path)
        File.write(path, to_yaml)
      end

      def [](key)
        Array(items).find { |i| i.url == key }&.name
      end

      def []=(key, value)
        item = Array(items).find { |i| i.url == key }
        if item
          item.name = value
        else
          items << CacheIndexItem.new(url: key, name: value)
        end
      end

      def delete(key)
        item = Array(items).find { |i| i.url == key }
        items.delete(item) if item
      end
    end

    class Cache
      MAX_FILENAME_SIZE = 255

      include Locking

      attr_reader :cache_path

      def initialize(cache_path: nil)
        @cache_path = cache_path || Fontist.downloads_path
      end

      def self.lock_path(path)
        "#{path}.lock"
      end

      def fetch(key)
        map = load_cache
        if Fontist.use_cache? && cache_exist?(map[key])
          print_cached(map[key])

          return downloaded_file(map[key])
        end

        generated_file = yield
        path = save_cache(generated_file, key)

        downloaded_file(path)
      end

      def already_fetched?(keys)
        map = load_cache
        keys.find { |k| cache_exist?(map[k]) }
      end

      def delete(key)
        lock(lock_path) do
          map = load_cache
          return unless map[key]

          value = map.delete(key)
          map.to_file(cache_map_path)
          value
        end
      end

      def set(key, value)
        lock(lock_path) do
          map = load_cache
          map[key] = value
          map.to_file(cache_map_path)
        end
      end

      private

      def cache_map_path
        @cache_path.join("map.yml")
      end

      def load_cache
        CacheIndex.from_file(cache_map_path)
      end

      def downloaded_file(path)
        File.new(downloaded_path(path), "rb")
      end

      def cache_exist?(path)
        path && File.exist?(downloaded_path(path))
      end

      def downloaded_path(path)
        @cache_path.join(path)
      end

      def print(path)
        Fontist.ui.say("Fetched from cache: #{size(path)} MiB.")
      end

      def print_cached(path)
        size_mb = size(path)
        if size_mb > 0
          Fontist.ui.say("Fetched from cache: #{size_mb} MiB.")
        else
          Fontist.ui.say("Using cached file.")
        end
      end

      def size(path)
        File.size(downloaded_path(path)) / (1024 * 1024)
      end

      def save_cache(generated_file, key)
        path = move_to_downloads(generated_file)

        lock(lock_path) do
          map = load_cache
          map[key] = path
          map.to_file(cache_map_path)
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
        unless @cache_path.exist?
          FileUtils.mkdir_p(@cache_path)
        end
      end

      def generate_file_path(source)
        # WORKAROUND: `to_s` below is needed to avoid ArgumentError
        # on `Dir.mktmpdir`, which occurs in ruby-3.4-preview2.
        # Double-check on stable ruby-3.4 and remove if no longer needed.

        dir = Dir.mktmpdir(nil, @cache_path.to_s)
        File.join(dir, filename(source))
      end

      def filename(source)
        filename = response_to_filename(source)
        format_filename(filename)
      end

      def response_to_filename(source)
        if File.extname(source.original_filename).empty? && source.content_type
          require "marcel"
          ext = extension_from_mime(source.content_type)
          return "#{source.original_filename}.#{ext}" if ext
        end

        source.original_filename
      end

      def extension_from_mime(content_type)
        # Common MIME type to extension mapping
        case content_type
        when "application/zip" then "zip"
        when "application/x-tar" then "tar"
        when "application/gzip", "application/x-gzip" then "gz"
        when "application/x-7z-compressed" then "7z"
        when "application/octet-stream" then "bin"
        when "application/vnd.ms-cab-compressed" then "cab"
        else
          # Fallback: extract from MIME type subtype
          content_type.split("/").last.gsub(/[^a-z0-9]/, "")
        end
      end

      def format_filename(filename)
        return filename unless filename.length > MAX_FILENAME_SIZE

        ext = File.extname(filename)
        target_size = MAX_FILENAME_SIZE - ext.length
        cut_filename = filename.slice(0, target_size)
        "#{cut_filename}#{ext}"
      end

      def move(source_file, target_path)
        # Windows requires file descriptors to be closed before files are moved
        source_file.close
        FileUtils.mv(source_file.path, target_path)
      end

      def relative_to_downloads(path)
        Pathname.new(path).relative_path_from(@cache_path).to_s
      end
    end
  end
end
