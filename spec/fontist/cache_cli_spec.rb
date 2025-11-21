require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CacheCLI do
  after(:context) do
    restore_default_settings
  end

  describe "#clear" do
    let(:downloads_path) { Pathname.new "/fontist/download" }
    let(:system_index) { Pathname.new "/fontist/system_index" }
    let(:system_index2) { Pathname.new "/fontist/system_index2" }
    let(:command) { described_class.start(["clear"]) }
    let(:status) { command }

    before do
      expect(Fontist).to receive(:downloads_path).and_return(downloads_path)
      expect(Fontist).to receive(:system_index_path)
        .and_return(system_index)
        .at_least(:once)
      expect(Fontist).to receive(:system_preferred_family_index_path)
        .and_return(system_index2)
        .at_least(:once)
    end

    it "download deleted" do
      cache_file = Pathname.new("/fontist/download/cache_file")
      allow(cache_file).to receive(:rmtree)

      expect(downloads_path).to receive(:exist?).and_return(true)
      expect(downloads_path).to receive(:each_child) { |&b| b.call(cache_file) }

      command

      expect(status).to be Fontist::CLI::STATUS_SUCCESS
    end

    it "indexes deleted" do
      expect(system_index).to receive(:exist?).and_return(true)
      expect(system_index2).to receive(:exist?).and_return(true)

      expect(Fontist.system_index_path).to receive(:delete).once
      expect(
        Fontist.system_preferred_family_index_path,
      ).to receive(:delete).once

      command

      expect(status).to be Fontist::CLI::STATUS_SUCCESS
    end

    it "works if download directory not exists" do
      allow(downloads_path).to receive(:exist?).and_return(false)
      allow(Fontist).to receive(:downloads_path).and_return(downloads_path).once
      expect(Fontist.ui).to receive(:success)
        .with("Cache has been successfully removed.")

      command

      expect(status).to be Fontist::CLI::STATUS_SUCCESS
    end
  end
end
