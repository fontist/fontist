require "spec_helper"

RSpec.describe Fontist::Utils::Downloader do
  let(:url) { sample_file[:file] }

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

    context "tampered file" do
      it "prints warning and returns file" do
        url = sample_file[:file]
        sha = sample_file[:sha]
        original_sha = "#{sample_file[:sha]}123"

        expect(Fontist.ui).to receive(:error).with(
          "SHA256 checksum mismatch for #{url}: #{sha}, " \
          "should be #{original_sha}.",
        )

        file = Fontist::Utils::Downloader.download(
          url,
          sha: original_sha,
          file_size: sample_file[:file_size],
        )

        expect(file).not_to be_nil
      end
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

    context "timeout error on the first request" do
      it "retries to download" do
        expect(Down).to receive(:download).and_raise(Down::TimeoutError).once
        expect(Down).to receive(:download).and_call_original.once

        expect do
          avoid_cache(sample_file[:file]) do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end
        end.not_to raise_error
      end
    end

    context "not-found error 3 times" do
      it "raises the invalid resource error" do
        avoid_cache(sample_file[:file]) do
          expect(Down).to receive(:download)
            .and_raise(Down::NotFound, "not found").exactly(3).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)
        end
      end
    end

    context "file has no extension" do
      it "uses content-type to detect extension" do
        avoid_cache(url) do
          expect(Down).to receive(:download).and_wrap_original do |m, *args|
            m.call(*args).tap do |file|
              allow(file).to receive(:original_filename)
                .and_return("no_ext_filename")
              allow(file).to receive(:content_type)
                .and_return("application/zip")
            end
          end

          file = Fontist::Utils::Downloader.download(url)
          expect(File.basename(file.path)).to eq "no_ext_filename.zip"
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
