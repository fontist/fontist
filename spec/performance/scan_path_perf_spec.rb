require "spec_helper"
require "stringio"

RSpec.describe ScanPathPerformance do
  let(:calls) { [] }
  let(:output) { StringIO.new }
  let(:sampler) do
    lambda do |tier, workload|
      calls << [tier, workload]
      { "elapsed" => tier == "ruby" ? 2.0 : 1.0, "rss" => 100.0 }
    end
  end
  let(:gate) do
    described_class::Gate.new("native", sampler: sampler, output: output)
  end

  it "alternates Ruby and the forced tier for five rounds" do
    expect(gate.passes?("index")).to be true
    expect(calls.map(&:first)).to eq %w[ruby native native ruby ruby native
                                        native ruby ruby native]
    expect(calls.map(&:last).uniq).to eq ["index"]
  end

  it "compares medians rather than a noisy outlier" do
    allow(sampler).to receive(:call).and_wrap_original do |orig, tier, job|
      sample = orig.call(tier, job)
      sample["elapsed"] = 100.0 if calls.size == 2
      sample
    end

    expect(gate.passes?("validator")).to be true
    expect(calls.size).to eq 10
  end

  it "accepts equal time and exactly three percent extra peak RSS" do
    allow(sampler).to receive(:call) do |tier, _|
      { "elapsed" => 1.0, "rss" => tier == "ruby" ? 100.0 : 103.0 }
    end

    expect(gate.passes?("index")).to be true
  end

  %w[elapsed rss].each do |metric|
    it "confirms a #{metric} regression with five more alternating rounds" do
      allow(sampler).to receive(:call).and_wrap_original do |orig, tier, job|
        sample = orig.call(tier, job)
        sample[metric] = 200.0 if tier == "native"
        sample
      end

      expect(gate.passes?("index")).to be false
      expect(calls.size).to eq 20
      expect(calls.map(&:first).last(10)).to eq %w[native ruby ruby native
                                                   native ruby ruby native
                                                   native ruby]
    end
  end

  it "passes when the confirmation measurements recover" do
    allow(sampler).to receive(:call).and_wrap_original do |orig, tier, job|
      sample = orig.call(tier, job)
      sample["elapsed"] = 3.0 if tier == "native" && calls.size <= 10
      sample
    end

    expect(gate.passes?("index")).to be true
    expect(calls.size).to eq 20
  end

  it "rejects a missing tier instead of retrying it as a regression" do
    allow(sampler).to receive(:call).and_raise(described_class::Error,
                                               "native unavailable")

    expect do
      gate.passes?("index")
    end.to raise_error(described_class::Error,
                       "native unavailable")
    expect(sampler).to have_received(:call).once
  end

  it "rejects invalid measurements" do
    allow(sampler).to receive(:call).and_return({ "elapsed" => Float::NAN,
                                                  "rss" => 100 })

    expect do
      gate.passes?("index")
    end.to raise_error(described_class::Error,
                       /invalid elapsed/)
  end

  it "rejects auto selection" do
    expect do
      described_class::Gate.new("auto")
    end.to raise_error(described_class::Error,
                       /force native or ffi/)
  end

  it "reads GNU time peak RSS in bytes" do
    rss = described_class.peak_rss("Maximum resident set size (kbytes): 123\n")
    expect(rss).to eq 125_952
  end

  it "reads BSD time peak RSS in bytes" do
    rss = described_class.peak_rss("  125952  maximum resident set size\n")
    expect(rss).to eq 125_952
  end

  it "treats missing peak RSS as an error" do
    expect do
      described_class.peak_rss("")
    end.to raise_error(described_class::Error,
                       /missing peak RSS/)
  end

  describe ".sample" do
    let(:status) { instance_double(Process::Status, success?: true) }
    let(:document) do
      JSON.generate("elapsed" => 1.0, "served_by" => "native", "results" => 30)
    end

    before do
      allow(Open3).to receive(:capture3).and_return(
        [document, "  125952  maximum resident set size\n", status],
      )
    end

    it "forces strict routing and uses a fresh home for each measurement" do
      homes = []
      2.times { described_class.sample("native", "index") }

      expect(Open3).to have_received(:capture3).twice do |env, *|
        expect(env).to include("FONTISAN_ENGINE" => "native",
                               "FONTISAN_ENGINE_STRICT" => "1")
        homes << env.fetch("FONTIST_PATH")
      end
      expect(homes.uniq.size).to eq 2
    end

    it "returns the workload time and process peak RSS" do
      expect(described_class.sample("native", "validator")).to include(
        "elapsed" => 1.0, "rss" => 125_952,
      )
    end

    it "rejects a child that fell back to Ruby" do
      allow(Open3).to receive(:capture3).and_return(
        [document.sub("native", "ruby"), "", status],
      )

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /did not serve/)
    end

    it "rejects a child that scanned no fonts" do
      allow(Open3).to receive(:capture3).and_return(
        [document.sub("30", "0"), "", status],
      )

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /nonempty scan/)
    end

    it "reports an unavailable tier as an error" do
      allow(status).to receive_messages(success?: false, exitstatus: 2)
      allow(Open3).to receive(:capture3).and_return(
        ["", "native unavailable", status],
      )

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /exited 2: native unavailable/)
    end

    it "rejects malformed child output" do
      allow(Open3).to receive(:capture3).and_return(["not JSON", "", status])

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /measurement error/)
    end
  end

  # Run only the gate: FONTIST_PERF_TIER=native bundle exec rspec <this file>
  # Every child forces its tier with FONTISAN_ENGINE_STRICT=1.
  describe "fixture corpus scan", :scan_path_gate do
    %w[index validator].each do |workload|
      it "keeps #{workload} time and peak RSS within the Ruby tier floor" do
        perf_gate = described_class::Gate.new(ENV.fetch("FONTIST_PERF_TIER"))

        passed = perf_gate.passes?(workload)
        expect(passed).to be(true), "#{workload} regressed after confirmation"
      rescue StandardError, LoadError
        # RSpec normally reports every example exception as status 1. Preserve
        # the gate contract: unavailable tiers and broken measurements are 2.
        RSpec.configuration.failure_exit_code = 2
        raise
      end
    end
  end
end
