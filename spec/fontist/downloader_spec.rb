require "spec_helper"

RSpec.describe Fontist::Downloader do
  describe ".download", api_call: true do
    it "return the valid downloaded file" do
      tempfile = Fontist::Downloader.download(
        sample_file[:file],
        sha: sample_file[:sha],
        file_size: sample_file[:file_size],
      )

      expect(tempfile).not_to be_nil
      expect(tempfile.size).to eq(sample_file[:file_size])
    end

    it "raises an error for tempared file" do
      expect{
        Fontist::Downloader.download(
          sample_file[:file],
          sha: sample_file[:sha] + "mm",
          file_size: sample_file[:file_size]
        )
      }.to raise_error(Fontist::Error, "Invalid / Tempared file")
    end
  end

  def sample_file
    @sample_file ||= {
      file_size: 10132625,
      file: "https://unsplash.com/photos/ZXHgEIWELYA/download?force=true",
      sha: "b701889c51802f6f382206e6d0aa3509c8f98e10f26bd0725ae91d93e148fe7a"
    }
  end
end

