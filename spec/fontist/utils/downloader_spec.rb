require "spec_helper"
require "tempfile"

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
          cached_file.close

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

    context "retry policy" do
      # Built the way down's Net::HTTP backend builds it: the Net::HTTPResponse
      # is passed positionally. Doubles carrying #status or #headers are shapes
      # this backend never produces.
      def net_response(code, message, retry_after: nil)
        response_class = Net::HTTPResponse::CODE_TO_OBJ.fetch(code)
        response_class.new("1.1", code, message).tap do |response|
          response.add_field("Retry-After", retry_after) if retry_after
        end
      end

      def http_error(klass, code, message, retry_after: nil)
        response = net_response(code, message, retry_after: retry_after)
        klass.new("#{code} #{message}", response)
      end

      def rate_limit_error(retry_after: nil)
        http_error(Down::ClientError, "429", "Too Many Requests",
                   retry_after: retry_after)
      end

      # Pin rand to the top of its range so jittered delays are exact. Bounds
      # assertions would let a broken (or deleted) jitter pass, since the base
      # value is always in range.
      # At the maximum draw the tables become:
      #   [10, 20, 40, 60, 90] -> [13, 25, 50, 75, 113]
      #   [2, 4]               -> [3, 5]
      before do
        allow_any_instance_of(described_class)
          .to receive(:rand) { |_, range| range.max }
      end

      let(:jittered_table) { [13, 25, 50, 75, 113] }
      let(:jittered_transient) { [3, 5] }

      # A date header is a delay from now, so now has to be pinned the way
      # rand is. Building the header off the same instant keeps the expected
      # delay exact; httpdate drops sub-second precision, so a header built
      # from a live clock would round a second either way.
      let(:frozen_now) { Time.utc(2026, 1, 1, 12, 0, 0) }

      def freeze_now
        allow(Time).to receive(:now).and_return(frozen_now)
      end

      def record_sleeps
        [].tap do |sleeps|
          allow_any_instance_of(described_class)
            .to receive(:sleep) { |_, value| sleeps << value }
        end
      end

      # Stands in for a successful download without reaching the network.
      def downloaded_file
        Tempfile.new("fontist-download").tap do |file|
          file.write("ok")
          file.rewind
          file.define_singleton_method(:original_filename) { "ok.txt" }
          file.define_singleton_method(:content_type) { "text/plain" }
        end
      end

      it "backs off through the whole table before raising" do
        avoid_cache(sample_file[:file]) do
          sleeps = record_sleeps
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error).exactly(6).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)

          expect(sleeps).to eq(jittered_table)
        end
      end

      it "honors a retry-after header exactly, without jitter" do
        avoid_cache(sample_file[:file]) do
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: "45")).once
          expect(Down).to receive(:download).and_return(downloaded_file).once

          expect_any_instance_of(described_class).to receive(:sleep).with(45)

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.not_to raise_error
        end
      end

      it "caps a retry-after above the maximum" do
        avoid_cache(sample_file[:file]) do
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: "9999")).once
          expect(Down).to receive(:download).and_return(downloaded_file).once

          expect_any_instance_of(described_class).to receive(:sleep).with(120)

          Fontist::Utils::Downloader.download(sample_file[:file])
        end
      end

      it "honors a retry-after sent as an http date" do
        avoid_cache(sample_file[:file]) do
          freeze_now
          header = (frozen_now + 45).httpdate
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: header)).once
          expect(Down).to receive(:download).and_return(downloaded_file).once

          expect_any_instance_of(described_class).to receive(:sleep).with(45)

          Fontist::Utils::Downloader.download(sample_file[:file])
        end
      end

      it "caps an http date that is far in the future" do
        avoid_cache(sample_file[:file]) do
          freeze_now
          header = (frozen_now + 9999).httpdate
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: header)).once
          expect(Down).to receive(:download).and_return(downloaded_file).once

          expect_any_instance_of(described_class).to receive(:sleep).with(120)

          Fontist::Utils::Downloader.download(sample_file[:file])
        end
      end

      it "falls back to the table when the http date has already passed" do
        avoid_cache(sample_file[:file]) do
          freeze_now
          sleeps = record_sleeps
          header = (frozen_now - 45).httpdate
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: header)).exactly(6).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)

          expect(sleeps).to eq(jittered_table)
        end
      end

      it "falls back to the table when the retry-after is zero" do
        avoid_cache(sample_file[:file]) do
          sleeps = record_sleeps
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: "0")).exactly(6).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)

          expect(sleeps).to eq(jittered_table)
        end
      end

      it "falls back to the table when the retry-after is unparseable" do
        avoid_cache(sample_file[:file]) do
          sleeps = record_sleeps
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: "soon")).exactly(6).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)

          expect(sleeps).to eq(jittered_table)
        end
      end

      it "tells the user why it is waiting and for how long" do
        avoid_cache(sample_file[:file]) do
          expect(Down).to receive(:download)
            .and_raise(rate_limit_error(retry_after: "45")).once
          expect(Down).to receive(:download).and_return(downloaded_file).once
          allow_any_instance_of(described_class).to receive(:sleep)

          expect(Fontist.ui).to receive(:say)
            .with("Server asked us to slow down. Retrying in 45s...")

          Fontist::Utils::Downloader.download(sample_file[:file])
        end
      end

      it "recovers when a rate limited request succeeds after three failures" do
        avoid_cache(sample_file[:file]) do
          sleeps = record_sleeps
          attempts = 0

          allow(Down).to receive(:download) do
            attempts += 1
            raise rate_limit_error if attempts <= 3

            Tempfile.new("fontist-rate-limit-recovery").tap do |file|
              file.write("ok")
              file.rewind
              file.define_singleton_method(:original_filename) { "ok.txt" }
              file.define_singleton_method(:content_type) { "text/plain" }
            end
          end

          file = Fontist::Utils::Downloader.download(sample_file[:file])

          expect(file.read).to eq("ok")
          expect(attempts).to eq(4)
          expect(sleeps).to eq(jittered_table.first(3))
        end
      end

      it "does not treat a connection failure as a rate limit" do
        avoid_cache(sample_file[:file]) do
          sleeps = record_sleeps
          expect(Down).to receive(:download).and_raise(
            Down::ConnectionError.new(
              "Failed to open TCP connection to cdn.example.com:4291",
            ),
          ).exactly(3).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)

          expect(sleeps).to eq(jittered_transient)
        end
      end

      it "treats a redirect error carrying a hash response as transient" do
        avoid_cache(sample_file[:file]) do
          sleeps = record_sleeps
          # A 429 inside the hash, so misclassifying it would be visible: the
          # rate limited table would run instead of the transient one.
          response = net_response("429", "Too Many Requests")
          error = Down::ResponseError.new("Invalid Redirect URI: x",
                                          response: response)
          # down passes `response:` to a keyword-less initializer, so this
          # lands as a Hash. If that ever changes, fail here rather than
          # silently stop covering the case.
          expect(error.response).to be_a(Hash)
          expect(Down).to receive(:download).and_raise(error).exactly(3).times

          expect do
            Fontist::Utils::Downloader.download(sample_file[:file])
          end.to raise_error(Fontist::Errors::InvalidResourceError)

          expect(sleeps).to eq(jittered_transient)
        end
      end

      context "each policy keeps its own counter" do
        it "gives a 429 its first delay after transient failures" do
          avoid_cache(sample_file[:file]) do
            sleeps = record_sleeps
            attempts = 0
            allow(Down).to receive(:download) do
              attempts += 1
              raise Down::TimeoutError, "timed out" if attempts <= 2

              raise rate_limit_error
            end

            expect do
              Fontist::Utils::Downloader.download(sample_file[:file])
            end.to raise_error(Fontist::Errors::InvalidResourceError)

            expect(sleeps.first(2)).to eq(jittered_transient)
            expect(sleeps.drop(2)).to eq(jittered_table)
          end
        end

        it "keeps the transient budget intact after a rate limit" do
          avoid_cache(sample_file[:file]) do
            sleeps = record_sleeps
            attempts = 0
            allow(Down).to receive(:download) do
              attempts += 1
              raise rate_limit_error if attempts == 1

              raise Down::TimeoutError, "timed out"
            end

            expect do
              Fontist::Utils::Downloader.download(sample_file[:file])
            end.to raise_error(Fontist::Errors::InvalidResourceError)

            expect(sleeps.first(1)).to eq(jittered_table.first(1))
            expect(sleeps.drop(1)).to eq(jittered_transient)
          end
        end
      end

      context "the server asks us to wait without sending a 429" do
        [["503", "Service Unavailable", Down::ServerError],
         ["403", "Forbidden", Down::ClientError]].each do |code, msg, klass|
          it "backs off on a #{code} carrying retry-after" do
            avoid_cache(sample_file[:file]) do
              expect(Down).to receive(:download).and_raise(
                http_error(klass, code, msg, retry_after: "30"),
              ).once
              expect(Down).to receive(:download)
                .and_return(downloaded_file).once
              expect_any_instance_of(described_class)
                .to receive(:sleep).with(30)

              Fontist::Utils::Downloader.download(sample_file[:file])
            end
          end
        end

        it "stays transient for a 404 with no retry-after" do
          avoid_cache(sample_file[:file]) do
            sleeps = record_sleeps
            expect(Down).to receive(:download)
              .and_raise(http_error(Down::NotFound, "404", "Not Found"))
              .exactly(3).times

            expect do
              Fontist::Utils::Downloader.download(sample_file[:file])
            end.to raise_error(Fontist::Errors::InvalidResourceError)

            expect(sleeps).to eq(jittered_transient)
          end
        end

        it "follows the header appearing and disappearing mid-sequence" do
          avoid_cache(sample_file[:file]) do
            sleeps = record_sleeps
            attempts = 0
            allow(Down).to receive(:download) do
              attempts += 1
              raise http_error(Down::ServerError, "503", "Service Unavailable",
                               retry_after: attempts.odd? ? "30" : nil)
            end

            expect do
              Fontist::Utils::Downloader.download(sample_file[:file])
            end.to raise_error(Fontist::Errors::InvalidResourceError)

            # Header waits are exact; table waits are jittered.
            expect(sleeps.size).to eq(5)
            expect(sleeps.values_at(0, 2, 4)).to eq([30, 30, 30])
            expect(sleeps.values_at(1, 3)).to eq(jittered_transient)
          end
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
