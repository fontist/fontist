module GoogleFontsFixtures
  # Load a Google Fonts JSON fixture
  #
  # @param name [Symbol] fixture name (:ttf, :vf, or :woff2)
  # @return [Hash] parsed JSON fixture
  def load_google_fonts_fixture(name)
    fixture_path = File.join(
      __dir__,
      "..",
      "fixtures",
      "google_fonts",
      "#{name}.json",
    )

    unless File.exist?(fixture_path)
      raise "Fixture not found: #{fixture_path}"
    end

    JSON.parse(File.read(fixture_path))
  end

  # Stub Net::HTTP to return fixture data based on URL
  #
  # @param fixture_name [Symbol] fixture name (:ttf, :vf, or :woff2)
  # @yield block to execute with stubbed HTTP
  def stub_google_fonts_api(fixture_name)
    # Load all fixtures at once for nested stub support
    @google_fonts_fixtures ||= {}
    @google_fonts_fixtures[fixture_name] =
      load_google_fonts_fixture(fixture_name)

    # Setup stub that routes to correct fixture based on URL
    allow(Net::HTTP).to receive(:get_response) do |uri|
      url_str = uri.to_s

      # Determine which fixture to use based on URL
      fixture_to_use = if url_str.include?("capability=VF")
                         @google_fonts_fixtures[:vf]
                       elsif url_str.include?("capability=WOFF2")
                         @google_fonts_fixtures[:woff2]
                       else
                         @google_fonts_fixtures[:ttf]
                       end

      # Create response
      response = Net::HTTPSuccess.new("1.1", "200", "OK")
      if fixture_to_use
        allow(response).to receive(:body).and_return(JSON.generate(fixture_to_use))
      else
        allow(response).to receive(:body).and_return('{"items":[]}')
      end
      response
    end

    yield if block_given?
  ensure
    # Clean up if this is the outermost stub
    if caller.none? do |line|
      line.include?("stub_google_fonts_api") && !line.include?(__FILE__)
    end
      @google_fonts_fixtures = nil
      RSpec::Mocks.space.proxy_for(Net::HTTP).reset if defined?(RSpec::Mocks)
    end
  end
end

RSpec.configure do |config|
  config.include GoogleFontsFixtures
end
