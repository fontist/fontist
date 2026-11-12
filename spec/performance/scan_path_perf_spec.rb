require "spec_helper"
require "stringio"
require "shellwords"

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

  describe "PR versus base" do
    let(:base) { File.join(Dir.tmpdir, "fontist-perf-base") }
    let(:checkout) { File.join(Dir.tmpdir, "fontist-perf-pr") }
    let(:samples) { [] }
    let(:pr_time) { 1.15 }
    let(:pr_rss) { 103.0 }
    let(:base_sampler) do
      lambda do |tier, workload, **options|
        samples << [tier, workload, options]
        pr = options.fetch(:checkout) == checkout
        { "elapsed" => pr ? pr_time : 1.0, "rss" => pr ? pr_rss : 100.0 }
      end
    end
    let(:comparison) do
      described_class::BaseGate.new(base, checkout: checkout,
                                          sampler: base_sampler, output: output)
    end

    it "alternates five rounds of strict Ruby against a shared corpus" do
      expect(comparison.passes?("validator")).to be true
      roots = samples.map { |_, _, options| options.fetch(:checkout) }
      expect(roots).to eq [base, checkout, checkout, base, base, checkout,
                           checkout, base, base, checkout]
      expect(samples.map(&:first).uniq).to eq ["ruby"]
      expect(samples.map { |_, _, opts| opts.fetch(:corpus) }.uniq)
        .to eq [Fontist.root_path.join("spec/fixtures/fonts").to_s]
    end

    context "when PR time exceeds fifteen percent" do
      let(:pr_time) { 1.16 }

      it "fails only after five confirmation rounds" do
        expect(comparison.passes?("index")).to be false
        expect(samples.size).to eq 20
      end
    end

    context "when PR peak RSS exceeds three percent" do
      let(:pr_rss) { 103.1 }

      it "fails only after five confirmation rounds" do
        expect(comparison.passes?("validator")).to be false
        expect(samples.size).to eq 20
      end
    end

    it "accepts recovery in the confirmation rounds" do
      allow(base_sampler).to receive(:call).and_wrap_original do |orig, *args,
                                                              **opts|
        sample = orig.call(*args, **opts)
        if opts[:checkout] == checkout && samples.size <= 10
          sample["elapsed"] =
            2.0
        end
        sample
      end

      expect(comparison.passes?("validator")).to be true
      expect(samples.size).to eq 20
    end

    it "reports an unrunnable base as an error" do
      allow(base_sampler).to receive(:call)
        .and_raise(described_class::Error, "base cannot run")

      expect do
        comparison.passes?("index")
      end.to raise_error(described_class::Error, "base cannot run")
      expect(base_sampler).to have_received(:call).once
    end

    it "rejects a missing base checkout" do
      expect do
        described_class::BaseGate.new("")
      end.to raise_error(described_class::Error, /missing PR base/)
    end
  end

  describe "workflow platform preflight" do
    let(:directory) { Dir.mktmpdir("fontist-perf-lock") }
    let(:output_path) { File.join(directory, "github-output") }
    let(:command) do
      workflow = YAML.load_file(".github/workflows/perf-gate.yml")
      steps = workflow.fetch("jobs").fetch("scan-path-performance")
        .fetch("steps")
      preflight = steps.find { |step| step["id"] == "fontisan_platform" }
      args = Shellwords.split(preflight.fetch("run"))
      args[0] = RbConfig.ruby
      args[-1] = metadata_stub + args.last
      args
    end
    let(:published_platform) { "arm64-darwin" }
    let(:metadata_stub) do
      <<~RUBY
        response = Net::HTTPOK.new("1.1", "200", "OK")
        response.define_singleton_method(:body) do
          JSON.generate([
            { "number" => "0.4.48", "platform" => "#{published_platform}" }
          ])
        end
        Net::HTTP.define_singleton_method(:start) do |*, **, &block|
          client = Object.new
          client.define_singleton_method(:get) { |_| response }
          block.call(client)
        end
      RUBY
    end

    after { FileUtils.remove_entry(directory) }

    %w[0.4.48 0.4.48-arm64-darwin 0.4.48-x86_64-darwin
       0.4.48-x86_64-linux-gnu].each do |entry|
      it "looks up the release version from fontisan (#{entry})" do
        File.write(File.join(directory, "Gemfile.lock"), <<~LOCK)
          GEM
            remote: https://rubygems.org/
            specs:
              fontisan (#{entry})

          PLATFORMS
            ruby

          DEPENDENCIES
            fontisan
        LOCK
        env = { "TARGET_OS" => "darwin", "TARGET_CPU" => "arm64",
                "GITHUB_OUTPUT" => output_path }

        stdout, stderr, status = Open3.capture3(env, *command, chdir: directory)

        expect(status.exitstatus).to eq(0), stderr
        expect(stdout).to include("fontisan 0.4.48 for arm64-darwin")
        expect(File.read(output_path)).to eq "platform=arm64-darwin\n"
      end
    end

    context "with only a source gem published" do
      let(:published_platform) { "ruby" }

      %w[x86_64-linux arm64-darwin x86_64-darwin].each do |platform|
        it "reports missing #{platform} binaries as error 2" do
          File.write(File.join(directory, "Gemfile.lock"), <<~LOCK)
            GEM
              remote: https://rubygems.org/
              specs:
                fontisan (0.4.48)
          LOCK
          cpu, os = platform.split("-")
          env = { "TARGET_OS" => os, "TARGET_CPU" => cpu,
                  "GITHUB_OUTPUT" => output_path }

          _, stderr, status = Open3.capture3(env, *command, chdir: directory)

          expect(status.exitstatus).to eq 2
          expect(stderr).to include("fontisan 0.4.48", platform,
                                    "published platforms: ruby")
          expect(File).not_to exist(output_path)
        end
      end
    end
  end

  describe "workflow base checkout" do
    let(:steps) do
      YAML.load_file(".github/workflows/perf-gate.yml")
        .fetch("jobs").fetch("scan-path-performance").fetch("steps")
    end

    it "checks out the exact PR base into a second directory only for PRs" do
      checkout = steps.find { |step| step["id"] == "base_checkout" }

      expect(checkout.fetch("if")).to eq "github.event_name == 'pull_request'"
      expect(checkout.fetch("with")).to include(
        "ref" => "${{ github.event.pull_request.base.sha }}",
        "path" => ".perf-base",
      )
      expect(checkout.fetch("uses")).to eq "actions/checkout@v4"
    end

    it "reports a failed base checkout as error 2" do
      guard = steps.find do |step|
        step["name"] == "Require pull request base checkout"
      end
      stdout, _, status = Open3.capture3(
        { "BASE_CHECKOUT_OUTCOME" => "failure" },
        "bash", "-c", guard.fetch("run")
      )

      expect(status.exitstatus).to eq 2
      expect(stdout).to include("base checkout failed")
    end

    it "reports an inaccessible base bundle directory as error 2" do
      install = steps.find do |step|
        step["name"] == "Install pull request base bundle"
      end
      Dir.mktmpdir do |dir|
        _, _, status = Open3.capture3("bash", "-ec", install.fetch("run"),
                                      chdir: dir)

        expect(status.exitstatus).to eq 2
      end
    end

    it "logs the skipped base comparison on push while still running tiers" do
      skip_step = steps.find do |step|
        step["name"] == "Skip PR-vs-base check on push"
      end
      expect(skip_step.fetch("if")).to eq "github.event_name != 'pull_request'"
      stdout, _, status = Open3.capture3("bash", "-c", skip_step.fetch("run"))

      expect(status.exitstatus).to eq 0
      expect(stdout).to include("comparison skipped")
      gate = steps.find do |step|
        step["name"] == "Run scan path performance gate"
      end
      expect(gate).not_to have_key("if")
      expect(gate.fetch("env").fetch("FONTIST_PERF_TIER"))
        .to eq "${{ matrix.tier }}"
    end
  end

  describe ".sample" do
    let(:status) { instance_double(Process::Status, success?: true) }
    let(:document) do
      JSON.generate("elapsed" => 1.0, "served_by" => "native", "results" => 30,
                    "code_root" => Fontist.root_path.to_s)
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

    it "runs the PR driver with the selected checkout bundle and code" do
      allow(Open3).to receive(:capture3).and_return(
        [document.sub("native", "ruby"),
         "  125952 maximum resident set size\n", status],
      )
      root = Fontist.root_path.to_s
      corpus = File.join(root, "spec/fixtures/fonts")
      described_class.sample("ruby", "validator", checkout: root,
                                                  corpus: corpus)

      expect(Open3).to have_received(:capture3) do |env, *args, **options|
        expect(env).to include("BUNDLE_GEMFILE" => File.join(root, "Gemfile"),
                               "FONTIST_PERF_CORPUS" => corpus)
        expect(args).to include(File.join(root, "spec/support/performance.rb"),
                                "-I#{root}/lib", "-rbundler/setup")
        expect(options).to include(chdir: root)
      end
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

    it "rejects measurements from the wrong checkout" do
      wrong = JSON.parse(document).merge("code_root" => "/wrong/checkout")
      allow(Open3).to receive(:capture3).and_return(
        [JSON.generate(wrong), "", status],
      )

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /wrong checkout/)
    end

    it "accepts a checkout reached through a filesystem alias" do
      Dir.mktmpdir do |dir|
        alias_path = File.join(dir, "checkout")
        File.symlink(Fontist.root_path, alias_path)

        expect do
          described_class.sample("native", "index", checkout: alias_path)
        end.not_to raise_error
      end
    end

    it "reports a base directory that cannot be entered as an error" do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

      expect do
        described_class.sample("ruby", "index", checkout: "/missing/base")
      end.to raise_error(described_class::Error, /measurement error/)
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

  describe "PR base corpus scan", :scan_path_base_gate do
    %w[index validator].each do |workload|
      it "keeps #{workload} time and RSS within the base checkout limits" do
        gate = described_class::BaseGate.new(ENV.fetch("FONTIST_PERF_BASE"))

        expect(gate.passes?(workload)).to be(true),
                                          "#{workload} regressed against base"
      rescue StandardError, LoadError
        RSpec.configuration.failure_exit_code = 2
        raise
      end
    end
  end

  describe "shared Fontist delay", :scan_path_gate, :scan_path_base_gate do
    let(:delayed_checkout) { Dir.mktmpdir("fontist-perf-delay") }

    after { FileUtils.remove_entry(delayed_checkout) }

    it "passes the tier floor but fails comparison with unchanged code" do
      reference = described_class.sample("ruby", "validator")
      %w[lib Gemfile Gemfile.lock fontist.gemspec].each do |path|
        FileUtils.cp_r(Fontist.root_path.join(path), delayed_checkout)
      end
      validator = File.join(delayed_checkout, "lib/fontist/validator.rb")
      original = File.read(validator)
      # This delay is in Fontist's shared scan path, before either tier runs.
      # Derive it from this run, rather than committing an absolute time budget.
      delayed = original.sub("def scan_results(paths)\n",
                             "def scan_results(paths)\n      " \
                             "sleep #{reference.fetch('elapsed') * 2}\n")
      expect(delayed).not_to eq(original)
      File.write(validator, delayed)
      delayed_sampler = lambda do |tier, workload|
        described_class.sample(tier, workload, checkout: delayed_checkout)
      end
      tier_gate = described_class::Gate.new(
        ENV.fetch("FONTIST_PERF_TIER"), sampler: delayed_sampler, output: output
      )
      base_gate = described_class::BaseGate.new(
        Fontist.root_path.to_s, checkout: delayed_checkout, output: output
      )

      expect(tier_gate.passes?("validator")).to be(true), output.string
      expect(base_gate.passes?("validator")).to be(false), output.string
    rescue StandardError, LoadError
      RSpec.configuration.failure_exit_code = 2
      raise
    end
  end
end
