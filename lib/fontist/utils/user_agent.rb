# frozen_string_literal: true

module Fontist
  module Utils
    module UserAgent
      PROFILES = [
        {
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36",
          platform: '"macOS"',
          chrome_version: "131",
        },
        {
          user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/130.0.0.0 Safari/537.36",
          platform: '"Windows"',
          chrome_version: "130",
        },
        {
          user_agent: "Mozilla/5.0 (X11; Linux x86_64) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/132.0.0.0 Safari/537.36",
          platform: '"Linux"',
          chrome_version: "132",
        },
        {
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/130.0.0.0 Safari/537.36",
          platform: '"macOS"',
          chrome_version: "130",
        },
        {
          user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/132.0.0.0 Safari/537.36",
          platform: '"Windows"',
          chrome_version: "132",
        },
      ].freeze

      ACCEPT = "text/html,application/xhtml+xml,application/xml;q=0.9," \
               "image/avif,image/webp,image/apng,*/*;q=0.8," \
               "application/signed-exchange;v=b3;q=0.7"

      ACCEPT_LANGUAGE = "en-US,en;q=0.9"

      STATIC_HEADERS = {
        "Accept" => ACCEPT,
        "Accept-Language" => ACCEPT_LANGUAGE,
        "Cache-Control" => "no-cache",
        "Pragma" => "no-cache",
        "Sec-Ch-Ua-Mobile" => "?0",
        "Sec-Fetch-Dest" => "document",
        "Sec-Fetch-Mode" => "navigate",
        "Sec-Fetch-Site" => "cross-site",
        "Sec-Fetch-User" => "?1",
        "Upgrade-Insecure-Requests" => "1",
      }.freeze

      class << self
        def random_profile
          PROFILES.sample
        end

        def browser_headers
          profile = random_profile
          build_headers(profile)
        end

        def random_user_agent
          random_profile[:user_agent]
        end

        private

        def build_headers(profile)
          STATIC_HEADERS.merge(
            "User-Agent" => profile[:user_agent],
            "Sec-Ch-Ua" => build_sec_ch_ua(profile[:chrome_version]),
            "Sec-Ch-Ua-Platform" => profile[:platform],
          )
        end

        def build_sec_ch_ua(chrome_version)
          "\"Google Chrome\";v=\"#{chrome_version}\", " \
            "\"Chromium\";v=\"#{chrome_version}\", " \
            "\"Not_A Brand\";v=\"24\""
        end
      end
    end
  end
end
