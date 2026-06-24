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

    context "checksum mismatch" do
      it "raises the invalid resource error" do
        avoid_cache(sample_file[:file]) do
          expect(Down).to receive(:download).and_call_original.once

          expect do
            Fontist::Utils::Downloader.download(
              sample_file[:file],
              sha: "#{sample_file[:sha]}123",
              file_size: sample_file[:file_size],
            )
          end.to raise_error(
            Fontist::Errors::InvalidResourceError,
            /SHA256 checksum mismatch/,
          )
        end
      end

      it "ignores existing cache entries when cache is disabled" do
        avoid_cache(sample_file[:file]) do
          Fontist::Utils::Downloader.download(
            sample_file[:file],
            sha: sample_file[:sha],
            file_size: sample_file[:file_size],
          )

          allow(Fontist).to receive(:use_cache?).and_return(false)
          expect(Down).to receive(:download).and_call_original.once

          expect do
            Fontist::Utils::Downloader.download(
              sample_file[:file],
              sha: "#{sample_file[:sha]}123",
              file_size: sample_file[:file_size],
            )
          end.to raise_error(
            Fontist::Errors::InvalidResourceError,
            /SHA256 checksum mismatch/,
          )
        end
      end
    end

    context "cached file checksum mismatch" do
      it "discards the cached file and retries with a fresh download" do
        avoid_cache(sample_file[:file]) do
          Fontist::Utils::Downloader.download(
            sample_file[:file],
            sha: sample_file[:sha],
            file_size: sample_file[:file_size],
          )

          expect(Down).to receive(:download).and_call_original.once

          attempt = 0
          allow(Digest::SHA256).to receive(:file).and_wrap_original do |m, *a|
            attempt += 1
            attempt == 1 ? "0" * 64 : m.call(*a)
          end

          file = Fontist::Utils::Downloader.download(
            sample_file[:file],
            sha: sample_file[:sha],
            file_size: sample_file[:file_size],
          )

          expect(file).not_to be_nil
        end
      end
    end

    context "no checksum given" do
      it "skips verification and returns the file" do
        avoid_cache(sample_file[:file]) do
          file = Fontist::Utils::Downloader.download(sample_file[:file])

          expect(file).not_to be_nil
        end
      end
    end

    context "cached file no longer matches its checksum" do
      it "discards the cached file instead of returning it" do
        avoid_cache(sample_file[:file]) do
          cached_file = Fontist::Utils::Downloader.download(
            sample_file[:file],
            sha: sample_file[:sha],
            file_size: sample_file[:file_size],
          )
          cached_path = Pathname.new(cached_file.path)

          allow(Digest::SHA256).to receive(:file).and_return("0" * 64)
          expect(Down).to receive(:download).and_call_original.once

          expect do
            Fontist::Utils::Downloader.download(
              sample_file[:file],
              sha: sample_file[:sha],
              file_size: sample_file[:file_size],
            )
          end.to raise_error(
            Fontist::Errors::InvalidResourceError,
            /SHA256 checksum mismatch/,
          )

          expect(cached_path.dirname).not_to exist
        end
      end
    end

    context "with headers" do
      let(:request) do
        Struct.new(:url, :headers).new(
          sample_file[:file],
          { "Accept" => "application/octet-stream" },
        )
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
          expect(Down).to receive(:download).and_wrap_original do |m, *a, **kv|
            m.call(*a, **kv).tap do |file|
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

    context "read_timeout is specified in config" do
      include_context "fresh home"

      before do
        Fontist::Config.instance.set(:read_timeout, 20)
      end

      after do
        Fontist::Config.instance.delete(:read_timeout)
      end

      it "passes read_timeout to Down" do
        expect(Down).to receive(:download)
          .with(anything, hash_including(read_timeout: 20)).and_call_original

        avoid_cache(sample_file[:file]) do
          described_class.download(sample_file[:file])
        end
      end
    end

    context "browser headers" do
      it "sends browser-like headers with the download" do
        avoid_cache(sample_file[:file]) do
          expect(Down).to receive(:download).and_wrap_original do |m, *args, **kwargs|
            headers = kwargs[:headers]
            expect(headers["User-Agent"]).to start_with("Mozilla/5.0")
            expect(headers).to have_key("Sec-Ch-Ua")
            expect(headers).to have_key("Sec-Fetch-Dest")
            m.call(*args, **kwargs)
          end

          described_class.download(sample_file[:file])
        end
      end
    end
  end

  def sample_file
    @sample_file ||= {
      file_size: 7918,
      file: "https://filesamples.com/samples/document/csv/sample4.csv",
      sha: "d576fa191d9780cf5ec7c0158af192131d358e5d6f9ef52a4ca1c83f22808708",
    }
  end
end
