require "octokit"

module Fontist
  module Utils
    class GitHubClient
      class << self
        def authenticated_download_url(parsed_url)
          return parsed_url.original_url unless parsed_url.matched?

          client = create_client
          release = fetch_release(client, parsed_url)

          find_asset_url(release, parsed_url.asset) || parsed_url.original_url
        rescue Octokit::Error => e
          Fontist.ui.say("GitHub API error: #{e.message}. Falling back to direct download.")
          parsed_url.original_url
        end

        private

        def create_client
          if github_token
            Octokit::Client.new(access_token: github_token)
          else
            Octokit::Client.new
          end
        end

        def github_token
          ENV.fetch("GITHUB_TOKEN", nil)
        end

        def fetch_release(client, parsed_url)
          client.release_for_tag("#{parsed_url.owner}/#{parsed_url.repo}", parsed_url.tag)
        end

        def find_asset_url(release, asset_name)
          release.assets.find { |asset| asset.name == asset_name }&.browser_download_url
        end
      end
    end
  end
end
