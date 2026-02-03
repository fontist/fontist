module Fontist
  module Resources
    class AppleCDNResource
      def initialize(resource, options = {})
        @resource = resource
        @options = options
      end

      def files(source_names, &block)
        archive_path = download_archive

        extract_archive(archive_path) do |extracted_dir|
          find_fonts(extracted_dir, source_names).each(&block)
        end
      end

      private

      def download_archive
        url = @resource.urls.first
        cache_path = Utils::Cache.file_path(url)

        return cache_path if File.exist?(cache_path)

        Fontist.ui.say("Downloading from Apple CDN...")
        Utils::Downloader.download(
          url,
          sha: @resource.sha256&.first,
          file_size: @resource.file_size,
          progress_bar: !@options[:no_progress],
        )
      end

      def extract_archive(archive_path)
        Dir.mktmpdir do |_temp_dir|
          Fontist.ui.say("Extracting fonts...")
          Excavate::Archive.new(archive_path).files(recursive_packages: true) do |path|
            yield File.dirname(path)
            break
          end
        end
      end

      def find_fonts(dir, source_files)
        source_files.flat_map do |filename|
          Dir.glob(File.join(dir, "**", filename))
        end
      end
    end
  end
end
