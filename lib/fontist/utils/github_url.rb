module Fontist
  module Utils
    class GitHubUrl
      GITHUB_RELEASE_PATTERN =
        %r{^https?://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/releases/download/(?<tag>[^/]+)/(?<asset>.+)$}

      class << self
        def match?(url)
          parse(url).matched?
        end

        def parse(url)
          url_string = url.to_s
          match = url_string.match(GITHUB_RELEASE_PATTERN)

          if match
            ParsedUrl.new(
              owner: match[:owner],
              repo: match[:repo],
              tag: match[:tag],
              asset: match[:asset],
              original_url: url_string
            )
          else
            ParsedUrl.from_non_github_url(url_string)
          end
        end
      end

      class ParsedUrl
        attr_reader :owner, :repo, :tag, :asset, :original_url

        def initialize(owner:, repo:, tag:, asset:, original_url:)
          @owner = owner
          @repo = repo
          @tag = tag
          @asset = asset
          @original_url = original_url
        end

        def self.from_non_github_url(original_url)
          new(owner: nil, repo: nil, tag: nil, asset: nil, original_url: original_url)
        end

        def matched?
          !owner.nil?
        end
      end
    end
  end
end
