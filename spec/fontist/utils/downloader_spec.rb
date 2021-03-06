require "spec_helper"

RSpec.describe Fontist::Utils::Downloader do
  describe ".download" do
    it "return the valid downloaded file" do
      tempfile = Fontist::Utils::Downloader.download(
        sample_file[:file],
        sha: sample_file[:sha],
        file_size: sample_file[:file_size],
      )

      expect(tempfile).not_to be_nil
      expect(tempfile.size).to eq(sample_file[:file_size])
    end

    it "raises an error for tempared file" do
      expect{
        Fontist::Utils::Downloader.download(
          sample_file[:file],
          sha: sample_file[:sha] + "mm",
          file_size: sample_file[:file_size]
        )
      }.to raise_error(Fontist::Errors::TamperedFileError)
    end

    context "with headers" do
      let(:request) do
        OpenStruct.new(url: sample_file[:file],
                       headers: { "Accept" => "application/octet-stream" })
      end

      it "uses them" do
        avoid_cache(request.url) do
          expect(Down).to receive(:download).and_call_original
          tempfile = Fontist::Utils::Downloader.download(request)
          expect(tempfile).not_to be_nil
        end
      end
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

