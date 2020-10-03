require_relative "cache"

module Fontist
  module Utils
    class Downloader
      def initialize(file, file_size: nil, sha: nil, progress_bar: nil)
        # TODO: If the first mirror fails, try the second one
        @file = file
        @sha = [sha].flatten.compact
        @progress_bar = set_progress_bar(progress_bar)
        @file_size = (file_size || default_file_size).to_i
        @cache = Cache.new
      end

      def download
        file = @cache.fetch(@file) { download_file }

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
        ENV.fetch("TEST_ENV", "") === "CI" ? false : progress_bar
      end

      def download_file
        bar = ProgressBar.new(file_size / byte_to_megabyte)

        file = Down.download(
          @file,
          open_timeout: 10,
          read_timeout: 10,
          content_length_proc: ->(content_length) {
            bar.total = content_length / byte_to_megabyte if content_length
          },
          progress_proc: -> (progress) {
            bar.increment(progress / byte_to_megabyte) if @progress_bar === true
          }
        )

        puts if @progress_bar === true

        file
      rescue Down::NotFound
        raise(Fontist::Errors::InvalidResourceError.new("Invalid URL: #{@file}"))
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
        complete = sprintf("%#.2f%%", ((@counter.to_f / @total.to_f) * 100))
        print "\r\e[0KDownloads: #{@counter}MB/#{@total}MB (#{complete})"
        @counter = progress
      end
    end
  end
end
