require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CacheCLI do
  describe "#clear" do
    let(:downloads_path) { Pathname.new "/fontist/download" }
    let(:command) { described_class.start(["clear"]) }
    let(:status) { command }

    it "content deleted" do
      cache_file = double("download cache file")

      expect(cache_file).to receive(:delete).once
      expect(downloads_path).to receive(:exist?).and_return(true)
      expect(downloads_path).to receive(:each_child) { |&b| b.call(cache_file) }
      expect(Fontist).to receive(:downloads_path).and_return(downloads_path)

      command

      expect(status).to be Fontist::CLI::STATUS_SUCCESS
    end

    it "works if download directory not exists" do
      allow(downloads_path).to receive(:exist?).and_return(false)
      allow(Fontist).to receive(:downloads_path).and_return(downloads_path).once
      expect(Fontist.ui).to receive(:success)
        .with("Download cache has been successfully removed.")

      command

      expect(status).to be Fontist::CLI::STATUS_SUCCESS
    end
  end
end
