require "open3"
require "tempfile"

module Fontist
  module Utils
    class CurlDownloader
      CURL = "curl.exe".freeze

      def self.fallback?(error)
        available? && enotsock?(error)
      end

      def self.available?
        Gem.win_platform?
      end

      def self.enotsock?(error)
        node = error
        while node
          return true if node.is_a?(Errno::ENOTSOCK)

          node = node.cause
        end

        # Down flattens the MinGW OpenSSL errno into a message-only
        # Down::ConnectionError (no typed #cause), so match the text as a
        # last resort.
        msg = error.message.to_s
        msg.include?("not a socket") || msg.include?("ENOTSOCK")
      end

      def initialize(url, headers: {})
        @url = url
        @headers = headers
      end

      # Returns a Tempfile that satisfies the cache duck type:
      # #original_filename, #content_type, #path, #close.
      def download
        tempfile = Tempfile.new("fontist-curl", binmode: true)
        content_type = run(argv(tempfile.path))
        decorate(tempfile, content_type)
      end

      def argv(output_path)
        # rubocop:disable Style/FormatStringToken
        [CURL, "-fSL", "--retry", "3", *header_args,
         "-w", "%{content_type}", "-o", output_path, "--", @url]
        # rubocop:enable Style/FormatStringToken
      end

      private

      # Forward every header Down would have sent (User-Agent plus any
      # formula-specific Authorization/Referer/cookies), not just the UA.
      def header_args
        @headers.flat_map { |key, value| ["-H", "#{key}: #{value}"] }
      end

      # The body goes to -o; stdout carries only curl's -w content_type.
      def run(argv)
        out, err, status = Open3.capture3(*argv)
        return out.strip if status.success?

        raise Fontist::Errors::InvalidResourceError,
              "curl failed for #{@url}: #{err.strip}"
      end

      def decorate(tempfile, content_type)
        filename = File.basename(URI(@url).path)
        tempfile.define_singleton_method(:original_filename) { filename }
        # Cache derives an extension from content_type only when the URL has
        # no extname; curl's -w reports it so extensionless URLs still resolve,
        # matching the Down path.
        type = content_type unless content_type.to_s.empty?
        tempfile.define_singleton_method(:content_type) { type }
        tempfile
      end
    end
  end
end
