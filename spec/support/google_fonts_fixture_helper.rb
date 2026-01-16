# frozen_string_literal: true

# Test helper for Google Fonts fixtures
#
# This helper provides methods to fetch real Google Fonts data from the API
# and cache it via VCR. This avoids hardcoded URLs that become outdated.
#
# Usage:
#   - First time: Run tests with VCR_RECORD_MODE=new_episodes to record real API calls
#   - Subsequent runs: VCR replays the recorded responses
#   - To refresh: Delete cassettes and re-run with new_episodes mode
module GoogleFontsFixtureHelper
  # Fetch real font data from Google Fonts API (cached via VCR)
  #
  # @param family_name [String] The font family name (e.g., "ABeeZee")
  # @return [Fontist::Import::Google::Models::FontFamily, nil] The font family or nil
  def self.fetch_font_family(family_name)
    require "fontist/import/google"

    # Use the actual Google Fonts API
    # VCR will record/replay the HTTP responses
    fonts = Fontist::Import::Google::Api.items
    fonts.find { |f| f.family == family_name }
  end

  # Get a test font fixture with real data
  #
  # @param family_name [String] The font family name
  # @return [Fontist::Import::Google::Models::FontFamily] A font family for testing
  def self.fixture_font(family_name)
    fetch_font_family(family_name) || raise("Font family '#{family_name}' not found in Google Fonts API")
  end

  # Common test fonts with real data
  #
  # These are fetched from the actual Google Fonts API and cached via VCR
  def self.abeezee_fixture
    @abeezee_fixture ||= fixture_font("ABeeZee")
  end

  def self.roboto_fixture
    @roboto_fixture ||= fixture_font("Roboto")
  end

  def self.ar_one_sans_fixture
    @ar_one_sans_fixture ||= fixture_font("AR One Sans")
  end

  # Clear cached fixtures
  def self.clear_cache
    @abeezee = nil
    @roboto = nil
    @ar_one_sans = nil
  end
end
