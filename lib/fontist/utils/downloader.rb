require "time"

module Fontist
  module Utils
    class Downloader
      RATE_LIMITED_HTTP_STATUS = 429
      BACKOFF = {
        rate_limited: [10, 20, 40, 60, 90].freeze,
        transient: [2, 4].freeze,
      }.freeze
      MAX_RETRY_AFTER = 120
      JITTER_RATIO = 0.25

      class << self
        def download(*args)
          new(*args).download
        end
        ruby2_keywords :download if respond_to?(:ruby2_keywords, true)
      end

      def initialize(file,
                     file_size: nil,
                     sha: nil,
                     progress_bar: nil,
                     use_content_length: true,
                     cache_path: nil)
        # TODO: If the first mirror fails, try the second one
        @file = file
        @sha = [sha].flatten.compact
        @file_size = file_size.to_i if file_size
        @progress_bar = progress_bar
        @verbose = progress_bar == :verbose
        @use_content_length = use_content_length
        @cache = Cache.new(cache_path: cache_path)
        @tries = Hash.new(0)
      end

      def download
        cached = use_cached_file?
        file = fetch_file
        verify_checksum!(file)
        file
      rescue Fontist::Errors::TamperedFileError => e
        delete_cached_file(file)
        raise invalid_resource_error(e) unless cached

        retry_download_after_cache_mismatch
      end

      private

      attr_reader :file, :sha, :file_size

      def retry_download_after_cache_mismatch
        file = fetch_file
        verify_checksum!(file)
        file
      rescue Fontist::Errors::TamperedFileError => e
        delete_cached_file(file)
        raise invalid_resource_error(e)
      end

      def fetch_file
        @cache.fetch(url) { download_file }
      end

      def use_cached_file?
        Fontist.use_cache? && !!@cache.already_fetched?([url])
      end

      def delete_cached_file(file)
        cached_path = file&.path
        file&.close unless file&.closed?
        @cache.delete(url)

        FileUtils.rm_rf(Pathname.new(cached_path).dirname) if cached_path
      end

      def verify_checksum!(file)
        return if sha.empty?

        file_checksum = Digest::SHA256.file(file).to_s
        return if sha.include?(file_checksum)

        raise Fontist::Errors::TamperedFileError,
              "SHA256 checksum mismatch for #{url}: #{file_checksum}, " \
              "should be #{sha.join(', or ')}."
      end

      def invalid_resource_error(error)
        Fontist::Errors::InvalidResourceError.new(
          "Invalid resource: #{@file}. Error: #{error.message}.",
        )
      end

      def byte_to_megabyte
        @byte_to_megabyte ||= 1024 * 1024
      end

      def download_path
        options[:download_path] || Fontist.root_path.join("tmp")
      end

      def download_file
        print_download_start if @verbose
        do_download_file
      rescue Down::Error => e
        retry if retry_download?(e)

        raise Fontist::Errors::InvalidResourceError,
              "Invalid URL: #{@file}. Error: #{e.inspect}."
      end

      def retry_download?(error)
        response = http_response(error)
        requested = retry_after(response)
        backing_off = requested || rate_limited?(response)
        kind = backing_off ? :rate_limited : :transient
        delays = BACKOFF.fetch(kind)
        attempt = (@tries[kind] += 1)
        return false if attempt > delays.length

        wait(kind, requested || jitter(delays[attempt - 1]))
        true
      end

      def wait(kind, seconds)
        reason = if kind == :rate_limited
                   "Server asked us to slow down"
                 else
                   "Download failed"
                 end

        Fontist.ui.say("#{reason}. Retrying in #{seconds}s...")
        sleep(seconds)
      end

      # Spread retrying clients apart so they do not all return at once.
      # Rounding the bound rather than the draw keeps the smallest delays
      # spread too. Drawing first and rounding after loses them: a two second
      # delay scales to half a second, and any fraction of that rounds to
      # nothing, so every client would return at exactly two seconds.
      def jitter(seconds)
        seconds + rand(0..(seconds * JITTER_RATIO).round)
      end

      # down attaches the response to status errors, but its redirect errors
      # pass `response:` as a keyword to a keyword-less initializer (5.4.2), so
      # those carry a Hash instead. Requiring both methods we go on to use drops
      # the Hash, and drops any backend we could not read a status or header
      # from, which then falls back to the transient policy.
      def http_response(error)
        return unless error.is_a?(Down::ResponseError)

        response = error.response
        response if response.respond_to?(:code) && response.respond_to?(:[])
      end

      def rate_limited?(response)
        response && response.code.to_i == RATE_LIMITED_HTTP_STATUS
      end

      # nil unless the server asked for a wait we can use.
      def retry_after(response)
        return unless response

        seconds = retry_after_seconds(response["Retry-After"])
        [seconds, MAX_RETRY_AFTER].min if seconds&.positive?
      end

      # RFC 7231 allows delta-seconds or an HTTP date. Most responses carry no
      # header at all and most that do use digits, so both leave before the
      # date parse, which is the only branch that needs a rescue. A date
      # already past gives a negative delay, which the caller drops the same
      # way it drops a zero.
      def retry_after_seconds(value)
        header = value.to_s.strip
        return if header.empty?
        return header.to_i if header.match?(/\A\d+\z/)

        (Time.httpdate(header) - Time.now).round
      rescue ArgumentError
        nil
      end

      def print_download_start
        Fontist.ui.say("Downloading from: #{Paint[url, :cyan]}")
        if @verbose
          Fontist.ui.say("  Cache location: #{Paint[@cache.cache_path, :black,
                                                    :bright]}")
        end
      end

      def do_download_file
        progress_bar = create_progress_bar
        file = do_download_file_with_progress_bar(progress_bar)
        progress_bar.finish
        file
      end

      def create_progress_bar
        if @progress_bar && @progress_bar != :verbose
          ProgressBar.new(@file_size)
        elsif @verbose
          ProgressBar.new(@file_size)
        else
          NullProgressBar.new(@file_size)
        end
      end

      # rubocop:disable Metrics/MethodLength
      def do_download_file_with_progress_bar(progress_bar)
        Down.download(
          url,
          open_timeout: Fontist.open_timeout,
          read_timeout: Fontist.read_timeout,
          max_redirects: 10,
          headers: headers,
          content_length_proc: ->(content_length) {
            if @use_content_length && content_length
              progress_bar.total = content_length
            end
          },
          progress_proc: ->(progress) {
            progress_bar.increment(progress)
          },
        )
      end
      # rubocop:enable Metrics/MethodLength

      def url
        @url ||= begin
          raw_url = extract_raw_url
          github_aware_url(raw_url)
        end
      end

      def headers
        obj = Helpers.url_object(@file)
        formula_headers = (obj.respond_to?(:headers) &&
          obj.headers &&
          obj.headers.to_h.to_h { |k, v| [k.to_s, v] }) || {} # rubocop:disable Style/HashTransformKeys, Metrics/LineLength

        Utils::UserAgent.browser_headers.merge(formula_headers)
      end

      def extract_raw_url
        obj = Helpers.url_object(@file)
        obj.respond_to?(:url) ? obj.url : obj
      end

      def github_aware_url(raw_url)
        parsed = GitHubUrl.parse(raw_url)
        if parsed.matched?
          GitHubClient.authenticated_download_url(parsed)
        else
          raw_url
        end
      end
    end

    class ProgressBar
      def initialize(total)
        @counter = 0
        @total = total
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

        Fontist.ui.print(format(", %<mb_per_second>.2f MiB/s, done.\n",
                                mb_per_second: mb_per_second))
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
        Fontist.ui.print(format("\r\e[0KDownloading: %<downloaded>4d MiB",
                                downloaded: counter_mb))
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
