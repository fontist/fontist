require "spec_helper"

RSpec.describe Fontist::Utils::GitHubUrl do
  describe ".parse" do
    context "with a valid GitHub release URL" do
      let(:url) { "https://github.com/tonsky/FiraCode/releases/download/5.2/Fira_Code_v5.2.zip" }

      it "parses the URL components" do
        parsed = described_class.parse(url)

        expect(parsed.matched?).to be true
        expect(parsed.owner).to eq("tonsky")
        expect(parsed.repo).to eq("FiraCode")
        expect(parsed.tag).to eq("5.2")
        expect(parsed.asset).to eq("Fira_Code_v5.2.zip")
        expect(parsed.original_url).to eq(url)
      end
    end

    context "with a URL containing special characters" do
      let(:url) { "https://github.com/some-org/some-repo/releases/download/v1.0.0-beta/some_asset-v1.0.zip" }

      it "parses the URL components correctly" do
        parsed = described_class.parse(url)

        expect(parsed.matched?).to be true
        expect(parsed.owner).to eq("some-org")
        expect(parsed.repo).to eq("some-repo")
        expect(parsed.tag).to eq("v1.0.0-beta")
        expect(parsed.asset).to eq("some_asset-v1.0.zip")
      end
    end

    context "with a non-GitHub URL" do
      let(:url) { "https://example.com/file.zip" }

      it "returns an unmatched parsed URL" do
        parsed = described_class.parse(url)

        expect(parsed.matched?).to be false
        expect(parsed.owner).to be_nil
        expect(parsed.repo).to be_nil
        expect(parsed.tag).to be_nil
        expect(parsed.asset).to be_nil
        expect(parsed.original_url).to eq(url)
      end
    end

    context "with a GitHub URL that is not a release download" do
      let(:url) { "https://github.com/tonsky/FiraCode/blob/main/README.md" }

      it "returns an unmatched parsed URL" do
        parsed = described_class.parse(url)

        expect(parsed.matched?).to be false
        expect(parsed.original_url).to eq(url)
      end
    end
  end

  describe ".match?" do
    it "returns true for GitHub release URLs" do
      url = "https://github.com/tonsky/FiraCode/releases/download/5.2/Fira_Code_v5.2.zip"
      expect(described_class.match?(url)).to be true
    end

    it "returns false for non-GitHub URLs" do
      url = "https://example.com/file.zip"
      expect(described_class.match?(url)).to be false
    end

    it "returns false for non-release GitHub URLs" do
      url = "https://github.com/tonsky/FiraCode"
      expect(described_class.match?(url)).to be false
    end
  end
end

RSpec.describe Fontist::Utils::GitHubClient do
  describe ".authenticated_download_url" do
    let(:parsed_url) do
      Fontist::Utils::GitHubUrl::ParsedUrl.new(
        owner: "tonsky",
        repo: "FiraCode",
        tag: "5.2",
        asset: "Fira_Code_v5.2.zip",
        original_url: "https://github.com/tonsky/FiraCode/releases/download/5.2/Fira_Code_v5.2.zip"
      )
    end

    context "without GITHUB_TOKEN environment variable" do
      before { ENV.delete("GITHUB_TOKEN") }
      after { ENV.delete("GITHUB_TOKEN") }

      it "attempts Octokit and returns a valid URL" do
        result = described_class.authenticated_download_url(parsed_url)
        expect(result).to start_with("https://")
        expect(result).to include("Fira_Code_v5.2.zip")
      end

      it "falls back to original URL on API errors" do
        # Mock a scenario where the asset is not found in the release
        allow_any_instance_of(Octokit::Client).to receive(:release_for_tag).and_return(
          double("release", assets: [])
        )

        result = described_class.authenticated_download_url(parsed_url)
        expect(result).to eq(parsed_url.original_url)
      end
    end

    context "with GITHUB_TOKEN environment variable" do
      before { ENV["GITHUB_TOKEN"] = "ghp_test_token" }
      after { ENV.delete("GITHUB_TOKEN") }

      it "attempts Octokit with authentication and returns a valid URL" do
        result = described_class.authenticated_download_url(parsed_url)
        expect(result).to start_with("https://")
        expect(result).to include("Fira_Code_v5.2.zip")
      end
    end
  end
end

