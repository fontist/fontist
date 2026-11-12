require "spec_helper"
require_relative "../../script/performance/report-status"

RSpec.describe "Performance gate publication" do
  it "reports missing published engines on the PR for its exact head" do
    workflow = YAML.load_file(".github/workflows/perf-gate.yml")
    job = workflow.fetch("jobs")["report-engine-availability"]

    expect(job).not_to be_nil,
                       "missing engines are only reported in CI logs"
    expect(job.fetch("permissions")).to include("pull-requests" => "write")
    report = job.fetch("steps").find do |step|
      step["name"] == "Report published engines on the PR"
    end
    expect(report.fetch("env")).to include(
      "FONTIST_PERF_HEAD" => "${{ github.event.pull_request.head.sha }}",
    )
    expect(report.fetch("run")).to include("report-status.rb", "--publish")
  end
end

RSpec.describe ScanPathPublication::Report do
  let(:expected_head) { "a" * 40 }
  let(:remote_head) { expected_head }
  let(:platforms) { ["ruby"] }
  let(:report) do
    described_class.new(expected_head: expected_head, remote_head: remote_head,
                        version: "0.4.48", platforms: platforms)
  end

  it "names the missing version and every affected platform in the PR report" do
    expect(report.to_markdown).to include(
      "fontisan 0.4.48", "Linux x86_64", "x86_64-linux-gnu",
      "macOS arm64", "arm64-darwin", "macOS x86_64", "x86_64-darwin",
      "2 (error)", "D4", "ruby"
    )
    expect(report.exit_status).to eq 2
  end

  context "when the remote PR head is stale" do
    let(:remote_head) { "b" * 40 }
    let(:platforms) { %w[x86_64-linux-gnu arm64-darwin x86_64-darwin] }

    it "rejects CI on an older head even when all binaries are published" do
      expect(report).not_to be_current
      expect(report.exit_status).to eq 2
      expect(report.to_markdown).to include("stale", expected_head, remote_head,
                                            "does not validate")
    end
  end

  context "when all required platform gems are published" do
    let(:platforms) do
      %w[ruby x86_64-linux x86_64-linux-gnu arm64-darwin x86_64-darwin]
    end

    it "accepts the current head and available platform aliases" do
      expect(report).to be_current
      expect(report.missing_platforms).to be_empty
      expect(report.exit_status).to eq 0
    end
  end
end

RSpec.describe ScanPathPublication do
  let(:head) { "a" * 40 }
  let(:report) do
    described_class::Report.new(expected_head: head, remote_head: head,
                                version: "0.4.48", platforms: ["ruby"])
  end

  it "posts the missing binary report as a PR comment" do
    success = instance_double(Process::Status, success?: true)
    expect(Open3).to receive(:capture3) do |*args|
      expect(args.first(7)).to eq ["gh", "pr", "comment", "552", "--repo",
                                   "fontist/fontist", "--body-file"]
      expect(File.read(args.last)).to eq report.to_markdown
      ["https://github.com/fontist/fontist/pull/552#issuecomment-1", "",
       success]
    end

    expect(described_class.publish(report, "fontist/fontist", "552"))
      .to include("issuecomment-1")
  end

  it "uses the PR head supplied by CI instead of its synthetic merge commit" do
    lock = <<~LOCK
      GEM
        remote: https://rubygems.org/
        specs:
          fontisan (0.4.48)
    LOCK
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("Gemfile.lock").and_return(lock)
    expect(described_class).not_to receive(:command).with("git", "rev-parse",
                                                          "HEAD")
    allow(described_class).to receive(:command)
      .with("gh", "pr", "view", "552", "--repo", "fontist/fontist",
            "--json", "headRefOid")
      .and_return(JSON.generate("headRefOid" => head))
    metadata = [
      { "number" => "0.4.48", "platform" => "ruby" },
      { "number" => "0.4.47", "platform" => "arm64-darwin" },
    ]
    stub_request(:get, "https://rubygems.org/api/v1/versions/fontisan.json")
      .to_return(body: JSON.generate(metadata))

    collected = described_class.collect("fontist/fontist", "552",
                                        expected_head: head)

    expect(collected).to be_current
    expect(collected.to_markdown).to include("fontisan 0.4.48", "macOS arm64")
    expect(collected.exit_status).to eq 2
  end
end
