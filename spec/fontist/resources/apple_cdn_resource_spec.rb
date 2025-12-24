require "spec_helper"
require_relative "../../../lib/fontist/resources/apple_cdn_resource"

RSpec.describe Fontist::Resources::AppleCDNResource do
  let(:resource) do
    double(
      "Resource",
      urls: ["https://updates.cdn-apple.com/test/font.zip"],
      sha256: ["abc123"],
      file_size: 12345,
    )
  end

  subject(:apple_cdn_resource) do
    described_class.new(resource, no_progress: true)
  end

  describe "#initialize" do
    it "accepts resource and options" do
      expect(apple_cdn_resource).to be_a(described_class)
    end

    it "stores no_progress option" do
      resource_with_progress = described_class.new(resource, no_progress: false)
      expect(resource_with_progress.instance_variable_get(:@options)).to eq({ no_progress: false })
    end
  end

  describe "#files" do
    let(:mock_archive) { double("Archive") }
    let(:mock_cache_path) { "/tmp/cache/font.zip" }
    let(:mock_extracted_dir) { "/tmp/extracted" }
    let(:source_files) { ["AlBayan.ttc"] }

    before do
      allow(Fontist::Utils::Cache).to receive(:file_path).and_return(mock_cache_path)
      allow(File).to receive(:exist?).with(mock_cache_path).and_return(false)
      allow(Fontist::Utils::Downloader).to receive(:download).and_return(mock_cache_path)
      allow(Dir).to receive(:mktmpdir).and_yield(mock_extracted_dir)
      allow(Excavate::Archive).to receive(:new).and_return(mock_archive)
      allow(mock_archive).to receive(:files).and_yield("/tmp/extracted/AlBayan.ttc")
      allow(Dir).to receive(:glob).and_return(["/tmp/extracted/AlBayan.ttc"])
    end

    it "downloads from Apple CDN" do
      expect(Fontist::Utils::Downloader).to receive(:download)
        .with(
          "https://updates.cdn-apple.com/test/font.zip",
          hash_including(sha: "abc123", file_size: 12345)
        )
        .and_return(mock_cache_path)

      apple_cdn_resource.files(source_files) { |_path| }
    end

    it "uses cached file if available" do
      allow(File).to receive(:exist?).with(mock_cache_path).and_return(true)

      expect(Fontist::Utils::Downloader).not_to receive(:download)

      apple_cdn_resource.files(source_files) { |_path| }
    end

    it "extracts archive" do
      expect(Excavate::Archive).to receive(:new).with(mock_cache_path)
        .and_return(mock_archive)
      expect(mock_archive).to receive(:files)

      apple_cdn_resource.files(source_files) { |_path| }
    end

    it "yields font paths" do
      yielded_paths = []

      apple_cdn_resource.files(source_files) do |path|
        yielded_paths << path
      end

      expect(yielded_paths).not_to be_empty
    end

    it "finds fonts matching source files" do
      expect(Dir).to receive(:glob).with("/tmp/extracted/**/AlBayan.ttc")
        .and_return(["/tmp/extracted/AlBayan.ttc"])

      apple_cdn_resource.files(source_files) { |_path| }
    end
  end

  describe "error handling" do
    it "handles download failures gracefully" do
      allow(Fontist::Utils::Cache).to receive(:file_path).and_return("/tmp/cache/font.zip")
      allow(File).to receive(:exist?).and_return(false)
      allow(Fontist::Utils::Downloader).to receive(:download)
        .and_raise(Fontist::Errors::InvalidResourceError, "Download failed")

      expect do
        apple_cdn_resource.files(["test.ttf"]) { |_path| }
      end.to raise_error(Fontist::Errors::InvalidResourceError)
    end
  end
end