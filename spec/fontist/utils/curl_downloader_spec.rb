require "spec_helper"

RSpec.describe Fontist::Utils::CurlDownloader do
  let(:url) { "https://example.com/fonts/Foo.zip" }
  let(:user_agent) { "Mozilla/5.0 (test)" }
  let(:headers) do
    { "User-Agent" => user_agent, "Authorization" => "Bearer t0ken" }
  end

  def with_cause(outer, inner)
    begin
      raise inner
    rescue StandardError
      raise outer
    end
  rescue StandardError => e
    e
  end

  describe ".fallback?" do
    let(:enotsock) { Errno::ENOTSOCK.new }

    it "is true on Windows with an ENOTSOCK signature" do
      allow(Gem).to receive(:win_platform?).and_return(true)

      expect(described_class.fallback?(enotsock)).to be true
    end

    it "is false off Windows even with an ENOTSOCK error" do
      allow(Gem).to receive(:win_platform?).and_return(false)

      expect(described_class.fallback?(enotsock)).to be false
    end

    it "is false on Windows when the error is unrelated" do
      allow(Gem).to receive(:win_platform?).and_return(true)

      expect(described_class.fallback?(Down::NotFound.new("nope"))).to be false
    end
  end

  describe ".enotsock?" do
    context "typed errno" do
      it "is true for a bare Errno::ENOTSOCK" do
        expect(described_class.enotsock?(Errno::ENOTSOCK.new)).to be true
      end

      it "is true when the #cause chain contains Errno::ENOTSOCK" do
        error = with_cause(RuntimeError.new("wrapped"), Errno::ENOTSOCK.new)

        expect(described_class.enotsock?(error)).to be true
      end
    end

    context "message-only (no typed cause)" do
      it "is true for a Down::ConnectionError mentioning 'not a socket'" do
        error = Down::ConnectionError.new("Connection failed: not a socket")

        expect(error.cause).to be_nil
        expect(described_class.enotsock?(error)).to be true
      end

      it "is true for a message mentioning ENOTSOCK" do
        error = Down::ConnectionError.new("ENOTSOCK during connect")

        expect(described_class.enotsock?(error)).to be true
      end

      it "is false for an unrelated message" do
        error = Down::ConnectionError.new("connection reset by peer")

        expect(described_class.enotsock?(error)).to be false
      end
    end
  end

  describe "#argv" do
    subject(:argv) do
      described_class.new(url, headers: headers).argv("/tmp/out")
    end

    it "starts with the curl fail/follow flags" do
      expect(argv.first(4)).to eq(["curl.exe", "-fSL", "--retry", "3"])
    end

    it "forwards every header (not just User-Agent) and the output path" do
      expect(argv).to include("-H", "User-Agent: #{user_agent}")
      expect(argv).to include("Authorization: Bearer t0ken")
      expect(argv).to include("-o", "/tmp/out")
    end

    it "captures the response content type via -w" do
      # rubocop:disable Style/FormatStringToken
      expect(argv).to include("-w", "%{content_type}")
      # rubocop:enable Style/FormatStringToken
    end

    it "places the URL after -- so it can never be parsed as a flag" do
      separator = argv.index("--")

      expect(separator).not_to be_nil
      expect(argv.last).to eq(url)
      expect(argv[0...separator]).not_to include(url)
    end
  end

  describe "#download" do
    subject(:downloader) { described_class.new(url, headers: headers) }

    let(:success) { instance_double(Process::Status, success?: true) }
    let(:failure) { instance_double(Process::Status, success?: false) }

    it "raises InvalidResourceError on a non-zero curl exit" do
      allow(Open3).to receive(:capture3)
        .and_return(["", "curl: (22) 404", failure])

      expect { downloader.download }
        .to raise_error(Fontist::Errors::InvalidResourceError, /curl failed/)
    end

    it "sets content_type from curl's -w output (for extensionless URLs)" do
      allow(Open3).to receive(:capture3)
        .and_return(["application/zip\n", "", success])

      file = downloader.download

      expect(file.content_type).to eq("application/zip")
    ensure
      file&.close
    end

    it "leaves content_type nil when curl reports none" do
      allow(Open3).to receive(:capture3).and_return(["", "", success])

      file = downloader.download

      expect(file.original_filename).to eq("Foo.zip")
      expect(file.content_type).to be_nil
      expect(file.path).not_to be_nil
    ensure
      file&.close
    end
  end
end
