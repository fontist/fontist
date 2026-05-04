require "spec_helper"

RSpec.describe Fontist::Utils::UserAgent do
  describe ".random_profile" do
    it "returns a hash with required keys" do
      profile = described_class.random_profile
      expect(profile).to include(:user_agent, :platform, :chrome_version)
    end

    it "returns a profile from the pool" do
      profile = described_class.random_profile
      expect(described_class::PROFILES).to include(profile)
    end
  end

  describe ".random_user_agent" do
    it "returns a Chrome-like string" do
      ua = described_class.random_user_agent
      expect(ua).to be_a(String)
      expect(ua).to start_with("Mozilla/5.0")
      expect(ua).to include("Chrome")
      expect(ua).to include("AppleWebKit/537.36")
      expect(ua).to include("Safari/537.36")
    end
  end

  describe ".browser_headers" do
    subject(:headers) { described_class.browser_headers }

    it "returns a Hash with string keys and values" do
      expect(headers).to be_a(Hash)
      expect(headers.keys).to all(be_a(String))
      expect(headers.values).to all(be_a(String))
    end

    %w[
      User-Agent Accept Accept-Language Cache-Control Pragma
      Sec-Ch-Ua Sec-Ch-Ua-Mobile Sec-Ch-Ua-Platform
      Sec-Fetch-Dest Sec-Fetch-Mode Sec-Fetch-Site Sec-Fetch-User
      Upgrade-Insecure-Requests
    ].each do |key|
      it "includes the #{key} header" do
        expect(headers).to have_key(key)
      end
    end

    it "has a self-consistent User-Agent and Sec-Ch-Ua-Platform" do
      headers = described_class.browser_headers
      ua = headers["User-Agent"]
      platform = headers["Sec-Ch-Ua-Platform"]

      if ua.include?("Macintosh")
        expect(platform).to eq('"macOS"')
      elsif ua.include?("Windows")
        expect(platform).to eq('"Windows"')
      elsif ua.include?("Linux")
        expect(platform).to eq('"Linux"')
      end
    end

    it "has a self-consistent User-Agent and Sec-Ch-Ua" do
      headers = described_class.browser_headers
      ua = headers["User-Agent"]
      sec_ch_ua = headers["Sec-Ch-Ua"]

      chrome_version = ua.match(/Chrome\/(\d+)/)[1]
      expect(sec_ch_ua).to include("\"Google Chrome\";v=\"#{chrome_version}\"")
      expect(sec_ch_ua).to include("\"Chromium\";v=\"#{chrome_version}\"")
    end

    it "includes Not_A Brand in Sec-Ch-Ua" do
      expect(headers["Sec-Ch-Ua"]).to include('"Not_A Brand"')
    end

    it "sets Sec-Ch-Ua-Mobile to desktop" do
      expect(headers["Sec-Ch-Ua-Mobile"]).to eq("?0")
    end
  end

  describe "randomness" do
    it "returns different profiles across multiple calls" do
      samples = Array.new(20) { described_class.random_user_agent }
      unique = samples.uniq
      expect(unique.size).to be >= 2
    end
  end
end
