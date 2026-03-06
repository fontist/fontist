module Fontist
  module Resources
    class GoogleResource
      def initialize(resource, options = {})
        @resource = resource
        @options = options
      end

      def files(source_names)
        cached_paths = download_fonts(source_names)

        cached_paths.map do |path|
          Dir.mktmpdir do |dir|
            FileUtils.cp(path, dir)

            yield File.join(dir, File.basename(path))
          end
        end
      end

      private

      def download_fonts(source_names)
        urls = font_urls(source_names)

        urls.map do |url|
          download(url)
        end
      end

      def font_urls(source_names)
        # V5 formulas: files are basenames, urls are download URLs
        # V4/legacy: files are full URLs used for both naming and downloading
        if v5_resource?
          # Build basename->url mapping from parallel arrays
          basenames = Array(@resource.files)
          urls = Array(@resource.urls)
          basenames.each_with_index.filter_map do |basename, i|
            urls[i] if source_names.include?(format_filename(basename))
          end
        else
          @resource.files.select do |url|
            source_names.include?(path_to_source_file(url))
          end
        end
      end

      def v5_resource?
        urls = Array(@resource.urls)
        files = Array(@resource.files)
        urls.any? && files.any? && urls != files
      end

      def path_to_source_file(path)
        format_filename(File.basename(path))
      end

      # TODO: remove duplication, another in Cache
      def format_filename(filename)
        return filename unless filename.length > 255

        ext = File.extname(filename)
        target_size = 255 - ext.length
        cut_filename = filename.slice(0, target_size)
        "#{cut_filename}#{ext}"
      end

      def download(url)
        Fontist.ui.say(%(Downloading from #{url}))

        file = Utils::Downloader.download(
          url,
          use_content_length: false,
          progress_bar: !@options[:no_progress],
        )

        file.path
      end
    end
  end
end
