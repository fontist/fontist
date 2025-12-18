require "vcr"
require "cgi"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = {
    record: :none,
    allow_playback_repeats: true,
    match_requests_on: [:method, :host, :path],
  }

  # Filter sensitive API keys in both requests and responses
  config.filter_sensitive_data("<GOOGLE_FONTS_API_KEY>") do
    ENV["GOOGLE_FONTS_API_KEY"]
  end

  # Additional filtering for URL-encoded API keys
  config.before_record do |interaction|
    if ENV["GOOGLE_FONTS_API_KEY"]
      key = ENV["GOOGLE_FONTS_API_KEY"]
      # Replace in URI
      interaction.request.uri.gsub!(/key=#{Regexp.escape(key)}/, "key=<GOOGLE_FONTS_API_KEY>")
      # Replace URL-encoded version
      encoded_key = CGI.escape(key)
      interaction.request.uri.gsub!(/key=#{Regexp.escape(encoded_key)}/, "key=<GOOGLE_FONTS_API_KEY>")
    end
  end
end
