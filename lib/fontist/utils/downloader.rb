require_relative "cache"

module Fontist
  module Utils
    class Downloader
      def initialize(file, file_size: nil, sha: nil, progress_bar: nil)
        # TODO: If the first mirror fails, try the second one
        @file = file
        @sha = [sha].flatten.compact
        @file_size = (file_size || default_file_size).to_i
        @progress_bar = set_progress_bar(progress_bar)
        @cache = Cache.new
      end

      def download
        file = @cache.fetch(@file, bar: @progress_bar) do
          download_file
        end

        if !sha.empty? && !sha.include?(Digest::SHA256.file(file).to_s)
          raise(Fontist::Errors::TamperedFileError.new(
            "The downloaded file from #{@file} doesn't " \
            "match with the expected sha256 checksum!"
          ))
        end

        file
      end

      def self.download(file, options = {})
        new(file, options).download
      end

      private

      attr_reader :file, :sha, :file_size

      def default_file_size
        5 * byte_to_megabyte
      end

      def byte_to_megabyte
        @byte_to_megabyte ||= 1024 * 1024
      end

      def download_path
        options[:download_path] || Fontist.root_path.join("tmp")
      end

      def set_progress_bar(progress_bar)
        if ENV.fetch("TEST_ENV", "") === "CI" || progress_bar
          ProgressBar.new(@file_size)
        else
          NullProgressBar.new
        end
      end

      def download_file
        file = Down.download(
          @file,
          open_timeout: 10,
          read_timeout: 10,
          content_length_proc: ->(content_length) {
            @progress_bar.total = content_length if content_length
          },
          progress_proc: -> (progress) {
            @progress_bar.increment(progress)
          }
        )

        @progress_bar.finish

        file
      rescue Down::NotFound
        raise(Fontist::Errors::InvalidResourceError.new("Invalid URL: #{@file}"))
      end
    end

    class NullProgressBar
      def total=(_)
        # do nothing
      end

      def increment(_)
        # do nothing
      end

      def finish(_ = nil)
        # do nothing
      end
    end

    class ProgressBar
      def initialize(total)
        @counter = 1
        @total  = total
      end

      def total=(total)
        @total = total
      end

      def increment(progress)
        @counter = progress
        Fontist.ui.print "\r\e[0KDownloads: #{counter_mb}MB/#{total_mb}MB " \
                         "(#{completeness})"
      end

      def finish(message = nil)
        if message
          Fontist.ui.print " (#{message})\n"
        else
          Fontist.ui.print "\n"
        end
      end

      private

      def completeness
        sprintf("%#.2f%%", (@counter.fdiv(@total) * 100)) # rubocop:disable Style/FormatStringToken, Metrics/LineLength
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
    end
  end
end
