require "spec_helper"
RSpec.describe Fontist::Downloader do
  describe ".download", file_download: true do
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
      }.to raise_error(Fontist::Errors::TemparedFileError)
    end
  end

  def sample_file
    @sample_file ||= {
      file_size: 150899,
      file: "https://drive.google.com/u/0/uc?id=1Kk-rpLyQk98ubgxhTRKD2ZkMoY9KqKXk&export=download",
      sha: "5e513e4bfdada0ff10dd5b96414fcaeade84e235ce043865416ad7673cb6f3d8"
    }
  end
end

