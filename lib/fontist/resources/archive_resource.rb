module Fontist
  module Resources
    class ArchiveResource
      def initialize(resource, options = {})
        @resource = resource
        @options = options
      end

      def files(_source_names, &block)
        excavate.files(recursive_packages: true, &block)
      end

      private

      def excavate
        Excavate::Archive.new(archive.path)
      end

      def archive
        download_file(@resource)
      end

      def download_file(source)
        errors = []
        source.urls.each do |request|
          result = try_download_file(request, source)
          return result unless result.is_a?(Errors::InvalidResourceError)

          errors << result
        end

        raise Errors::InvalidResourceError, errors.join(" ")
      end

      def try_download_file(request, source)
        info_log(request)

        Fontist::Utils::Downloader.download(
          request,
          sha: source.sha256,
          file_size: source.file_size,
          progress_bar: !@options[:no_progress],
        )
      rescue Errors::InvalidResourceError => e
        Fontist.ui.say(e.message)
        e
      end

      def info_log(request)
        url = request.respond_to?(:url) ? request.url : request
        Fontist.ui.say(%(Downloading from #{url}))
      end
    end
  end
end
