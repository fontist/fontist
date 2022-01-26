require_relative "cache"

module Fontist
  module Utils
    class Downloader
      class << self
        def download(*args)
          new(*args).download
        end
        ruby2_keywords :download if respond_to?(:ruby2_keywords, true)
      end

      def initialize(file, file_size: nil, sha: nil, progress_bar: nil)
        # TODO: If the first mirror fails, try the second one
        @file = file
        @sha = [sha].flatten.compact
        @file_size = file_size.to_i if file_size
        @progress_bar = progress_bar
        @cache = Cache.new
      end

      def download
        file = @cache.fetch(url) do
          download_file
        end

        check_tampered(file)

        file
      end

      private

      attr_reader :file, :sha, :file_size

      def check_tampered(file)
        file_checksum = Digest::SHA256.file(file).to_s
        if !sha.empty? && !sha.include?(file_checksum)
          Fontist.ui.error(
            "SHA256 checksum mismatch for #{url}: #{file_checksum}, " \
            "should be #{sha.join(', or ')}.",
          )
        end
      end

      def byte_to_megabyte
        @byte_to_megabyte ||= 1024 * 1024
      end

      def download_path
        options[:download_path] || Fontist.root_path.join("tmp")
      end

      def download_file
        tries = tries ? tries + 1 : 1
        do_download_file
      rescue Down::Error => e
        retry if tries < 3

        raise Fontist::Errors::InvalidResourceError,
              "Invalid URL: #{@file}. Error: #{e.inspect}."
      end

      def do_download_file
        progress_bar = create_progress_bar
        file = do_download_file_with_progress_bar(progress_bar)
        progress_bar.finish
        file
      end

      def create_progress_bar
        if @progress_bar
          ProgressBar.new(@file_size)
        else
          NullProgressBar.new(@file_size)
        end
      end

      # rubocop:disable Metrics/MethodLength
      def do_download_file_with_progress_bar(progress_bar)
        Down.download(
          url,
          open_timeout: 10,
          read_timeout: 10,
          max_redirects: 10,
          headers: headers,
          content_length_proc: ->(content_length) {
            progress_bar.total = content_length if content_length
          },
          progress_proc: -> (progress) {
            progress_bar.increment(progress)
          }
        )
      end
      # rubocop:enable Metrics/MethodLength

      def url
        @file.respond_to?(:url) ? @file.url : @file
      end

      def headers
        @file.respond_to?(:headers) &&
          @file.headers &&
          @file.headers.to_h.map { |k, v| [k.to_s, v] }.to_h || # rubocop:disable Style/HashTransformKeys, Metrics/LineLength
          {}
      end
    end

    class ProgressBar
      def initialize(total)
        @counter = 0
        @total  = total
        @printed_percent = -1
        @printed_size = -1
        @start = Time.now
      end

      def total=(total)
        @total = total
      end

      def increment(progress)
        @counter = progress

        print_incrementally
      end

      def finish
        print

        Fontist.ui.print(format(", %<mb_per_second>.2f MiB/s, done.\n", mb_per_second: mb_per_second))
      end

      private

      def print_incrementally
        if total?
          print_percent_incrementally
        else
          print_size_incrementally
        end
      end

      def print
        if total?
          print_percent
        else
          print_size
        end
      end

      def total?
        !!@total
      end

      def print_percent_incrementally
        return unless percent > @printed_percent

        print_percent

        @printed_percent = percent
      end

      def print_percent
        # rubocop:disable Style/FormatStringToken
        Fontist.ui.print(format("\r\e[0KDownloading: %<completeness>3d%% (%<counter_mb>d/%<total_mb>d MiB)",
                                completeness: percent,
                                counter_mb: counter_mb,
                                total_mb: total_mb))
        # rubocop:enable Style/FormatStringToken
      end

      def percent
        (@counter.fdiv(@total) * 100).to_i
      end

      def counter_mb
        @counter / byte_to_megabyte
      end

      def total_mb
        @total / byte_to_megabyte
      end

      def byte_to_megabyte
        @byte_to_megabyte ||= 1024 * 1024
      end

      def print_size_incrementally
        return unless counter_mb > @printed_size

        print_size

        @printed_size = counter_mb
      end

      def print_size
        Fontist.ui.print(format("\r\e[0KDownloading: %<downloaded>4d MiB", downloaded: counter_mb))
      end

      def mb_per_second
        @counter / (Time.now - @start) / byte_to_megabyte
      end
    end

    class NullProgressBar < ProgressBar
      def print_incrementally
        # do nothing
      end
    end
  end
end
