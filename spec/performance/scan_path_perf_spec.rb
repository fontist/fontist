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

    it "fails equal timings when the PR loses the batch contract" do
      allow(base_sampler).to receive(:call).and_wrap_original do |original,
                                                                *args, **opts|
        original.call(*args, **opts).merge(
          "batch_contract" => opts.fetch(:checkout) != checkout,
        )
      end

      expect(comparison.passes?("validator")).to be false
      expect(samples.size).to eq 10
      expect(output.string).to include("batch_contract=false")
    end

    it "reports a baseline with lost batching as an error" do
      allow(base_sampler).to receive(:call).and_wrap_original do |original,
                                                                *args, **opts|
        original.call(*args, **opts).merge(
          "batch_contract" => opts.fetch(:checkout) == checkout,
        )
      end

      expect do
        comparison.passes?("validator")
      end.to raise_error(described_class::Error,
                         /base did not preserve the batch contract/)
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

  describe ".measure engine routing" do
    it "rejects Ruby workload routing after a successful native probe" do
      paths = ["first.ttf", "second.ttf"]
      allow(described_class).to receive(:prepare_scan)
      allow(described_class).to receive(:fixture_paths).and_return(paths)
      allow(Fontisan).to receive(:scan).and_return([{ "path" => paths.first }])
      allow(Fontisan::Engine).to receive(:served_by).with(:scan)
        .and_return(:native, :ruby)
      allow(described_class).to receive(:operation_for) do
        -> { Fontisan.scan(paths) }
      end

      expect do
        described_class.measure("validator")
      end.to raise_error(described_class::Error,
                         /workload scan served by "ruby", expected native/)
    end
  end

  describe ".cold_measurements" do
    let(:paths) { ["first.ttf", "second.ttf"] }
    let(:clock) { double("clock") }
    let(:operations) { [] }
    let(:duration) { 0.02 }
    let(:startup_noise) { 0.0 }

    before do
      allow(described_class).to receive(:prepare_scan)
      ticks = 0
      allow(clock).to receive(:call) do
        ticks += 1
        noise = ticks == 2 ? startup_noise : 0.0
        ticks.odd? ? 0.0 : duration + noise
      end
      allow(Fontisan).to receive(:scan).and_return([{ "path" => paths.first }])
      allow(described_class).to receive(:operation_for) do |_, _, **options|
        operations << options.fetch(:home)
        -> { Fontisan.scan(paths) }
      end
    end

    it "amortizes short operations over a minimum duration with fresh state" do
      sample = described_class.cold_measurements("validator", paths,
                                                 clock: clock)

      expect(sample).to include("elapsed" => be_within(0.000001).of(duration),
                                "iterations" => 50,
                                "batch_contract" => true, "results" => 1)
      expect(operations.uniq.size).to eq 50
      expect(described_class).to have_received(:prepare_scan).exactly(50).times
    end

    context "with a short startup disturbance" do
      let(:startup_noise) { 0.1 }

      it "amortizes noise without discarding the disturbed operation" do
        sample = described_class.cold_measurements("index", paths, clock: clock)

        expect(sample.fetch("elapsed") / duration).to be <= 1.15
        expect(sample.fetch("elapsed")).to be > duration
        expect(sample.fetch("iterations")).to eq 45
      end
    end

    context "with a stable twenty percent slowdown" do
      let(:duration) { 0.024 }

      it "preserves the slowdown after averaging and fails the base gate" do
        sample = described_class.cold_measurements("index", paths, clock: clock)
        measured_sampler = lambda do |_, _, **options|
          pr = options.fetch(:checkout) == described_class::ROOT
          sample.merge("elapsed" => pr ? sample.fetch("elapsed") : 0.02,
                       "rss" => 100.0)
        end
        comparison = described_class::BaseGate.new(
          "base", sampler: measured_sampler, output: output
        )

        expect(comparison.passes?("index")).to be false
        expect(output.string).to include("time=1.2", "attempt 2")
      end
    end

    context "with a long operation" do
      let(:duration) { 2.0 }

      it "still averages ten independent cold operations" do
        sample = described_class.cold_measurements("index", paths, clock: clock)

        expect(sample).to include("elapsed" => 2.0, "iterations" => 10)
        expect(operations.uniq.size).to eq 10
      end
    end

    it "detects a missing batch even with nonempty per-file results" do
      allow(described_class).to receive(:operation_for) do
        -> { paths }
      end

      sample = described_class.cold_measurements("validator", paths,
                                                 clock: clock)

      expect(sample).to include("batch_contract" => false, "results" => 2)
    end
  end

  describe "workflow tier matrix" do
    it "runs both strict tiers on supported runners for all three platforms" do
      job = YAML.load_file(".github/workflows/perf-gate.yml")
        .fetch("jobs").fetch("scan-path-performance")
      cells = job.fetch("strategy").fetch("matrix").fetch("include")
      entries = cells.map do |cell|
        cell.values_at("runner", "target_os", "target_cpu", "tier")
      end
      expected = [
        ["ubuntu-24.04", "linux", "x86_64", "native"],
        ["ubuntu-24.04", "linux", "x86_64", "ffi"],
        ["macos-latest", "darwin", "arm64", "native"],
        ["macos-latest", "darwin", "arm64", "ffi"],
        ["macos-15-intel", "darwin", "x86_64", "native"],
        ["macos-15-intel", "darwin", "x86_64", "ffi"],
      ]

      expect(job.fetch("runs-on")).to eq "${{ matrix.runner }}"
      expect(entries).to match_array(expected)
      gate = job.fetch("steps").find do |step|
        step["name"] == "Run scan path performance gate"
      end
      expect(gate.fetch("env")).to include("FONTISAN_ENGINE_STRICT" => "1")
    end
  end

  describe "card implementation layout" do
    it "keeps helpers and their regression specs in the card files" do
      %w[script/performance/report-status.rb
         script/performance/without-rust.rb
         spec/performance/publication_spec.rb].each do |path|
        expect(File).not_to exist(path), "#{path} is outside the card file list"
      end
    end

    it "runs publication and toolchain isolation from the card files" do
      jobs = YAML.load_file(".github/workflows/perf-gate.yml").fetch("jobs")
      report_steps = jobs.fetch("report-engine-availability").fetch("steps")
      report = report_steps.find do |step|
        step["name"] == "Report published engines on the PR"
      end
      expect(report.fetch("run")).to include("spec/support/performance.rb",
                                             "--report", "--publish")
      guards = %w[scan-path-base scan-path-performance].map do |job|
        jobs.fetch(job).fetch("steps").find do |step|
          step["name"] == "Exclude Rust toolchains from the job"
        end.fetch("run")
      end
      expect(guards.uniq.size).to eq 1
      expect(Shellwords.split(guards.first).first(2)).to eq ["ruby", "-e"]
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

  describe "workflow Rust isolation" do
    let(:directory) { Dir.mktmpdir("fontist-perf-path") }
    let(:toolchain) { File.join(directory, "rust bin") }
    let(:environment_file) { File.join(directory, "github-env") }
    let(:guard_command) do
      steps = YAML.load_file(".github/workflows/perf-gate.yml")
        .fetch("jobs").fetch("scan-path-base").fetch("steps")
      guard = steps.find do |step|
        step["name"] == "Exclude Rust toolchains from the job"
      end
      args = Shellwords.split(guard.fetch("run"))
      args[0] = RbConfig.ruby
      args
    end

    after { FileUtils.remove_entry(directory) }

    %w[cargo rustc rustup].each do |tool|
      it "makes an existing #{tool} unavailable while preserving Ruby" do
        FileUtils.mkdir_p(toolchain)
        executable = File.join(toolchain, "#{tool}#{RbConfig::CONFIG['EXEEXT']}")
        if Gem.win_platform?
          FileUtils.cp(RbConfig.ruby, executable)
        else
          File.write(executable, "#!/bin/sh\nexit 0\n")
        end
        File.chmod(0o755, executable)
        env = { "PATH" => [toolchain, ENV.fetch("PATH")].join(File::PATH_SEPARATOR),
                "GITHUB_ENV" => environment_file }
        stdout, stderr, status = Open3.capture3(env, *guard_command)

        expect(status.exitstatus).to eq(0), stdout + stderr
        clean_path = File.read(environment_file).delete_prefix("PATH=").strip
        stdout, stderr, status = Open3.capture3(
          { "PATH" => clean_path }, "bash", "-ec", <<~BASH
            if command -v cargo || command -v rustc || command -v rustup; then
              exit 2
            fi
            ruby --version
            bundle --version
          BASH
        )

        expect(status.exitstatus).to eq(0), stdout + stderr
        expect(stdout).to include("ruby")
      end
    end
  end

  describe "workflow base checkout" do
    let(:steps) do
      YAML.load_file(".github/workflows/perf-gate.yml")
        .fetch("jobs").fetch("scan-path-base").fetch("steps")
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
      tier_job = YAML.load_file(".github/workflows/perf-gate.yml")
        .fetch("jobs").fetch("scan-path-performance")
      expect(tier_job).not_to have_key("needs")
      gate = tier_job.fetch("steps").find do |step|
        step["name"] == "Run scan path performance gate"
      end
      expect(gate).not_to have_key("if")
      expect(gate.fetch("env").fetch("FONTIST_PERF_TIER"))
        .to eq "${{ matrix.tier }}"
      expect(gate.fetch("env")).not_to have_key("FONTIST_PERF_BASE")
    end

    it "runs the Ruby comparison without requiring published engines" do
      gate = steps.find do |step|
        step["name"] == "Run Ruby scan path performance gate"
      end

      expect(gate.fetch("env")).to include("FONTISAN_ENGINE" => "ruby",
                                           "FONTISAN_ENGINE_STRICT" => "1")
      expect(gate.fetch("env")).not_to have_key("FONTIST_PERF_TIER")
      expect(steps).not_to include(include("id" => "fontisan_platform"))
    end
  end

  describe "gate process contract" do
    let(:directory) { Dir.mktmpdir("fontist-perf-process") }
    let(:spec_path) { File.expand_path(__FILE__) }
    let(:env) do
      { "FONTIST_PERF_BASE" => base, "FONTIST_PERF_TIER" => tier,
        "FONTISAN_ENGINE" => "ruby", "GITHUB_EVENT_NAME" => "pull_request" }
    end
    let(:result) do
      driver = File.join(directory, "samples.rb")
      File.write(driver, <<~RUBY)
        module ScanPathPerformance
          def self.sample(tier, workload, **options)
            raise Error, "forced engine missing" if #{outcome.inspect} == "error"

            candidate = tier != "ruby" || options[:checkout] == ROOT
            elapsed = #{outcome.inspect} == "regression" && candidate ? 2.0 : 1.0
            { "elapsed" => elapsed, "rss" => 100.0 }
          end
        end
      RUBY
      Open3.capture3(env, RbConfig.ruby, "-S", "rspec", spec_path,
                     "--require", driver, "--example", selection,
                     "--format", "progress", "--no-profile")
    end

    after { FileUtils.remove_entry(directory) }

    context "with only the Ruby base check enabled" do
      let(:base) { File.join(directory, "base") }
      let(:tier) { nil }
      let(:selection) { "PR base corpus scan" }

      { "pass" => 0, "regression" => 1, "error" => 2 }.each do |outcome, code|
        context "when the measurement reports #{outcome}" do
          let(:outcome) { outcome }

          it "exits with #{code}" do
            stdout, stderr, status = result

            expect(status.exitstatus).to eq(code), stdout + stderr
            expect(stdout).to include("2 examples")
          end
        end
      end

      it "selects the real sleep regression without any native tier" do
        report = File.join(directory, "examples.json")
        _, stderr, status = Open3.capture3(
          env, RbConfig.ruby, "-S", "rspec", spec_path, "--dry-run",
          "--format", "json", "--out", report, "--no-profile"
        )

        expect(status.exitstatus).to eq(0), stderr
        examples = JSON.parse(File.read(report)).fetch("examples")
        names = examples.map { |example| example.fetch("full_description") }
        expect(names).to include(a_string_including("shared Fontist delay",
                                                    "fails comparison"))
        expect(names).not_to include(a_string_including("fixture corpus scan"))
      end
    end

    context "with only the tier check enabled" do
      let(:base) { nil }
      let(:tier) { "native" }
      let(:selection) { "fixture corpus scan" }

      it "does not select the base comparison just because it is a PR" do
        report = File.join(directory, "examples.json")
        _, stderr, status = Open3.capture3(
          env, RbConfig.ruby, "-S", "rspec", spec_path, "--dry-run",
          "--format", "json", "--out", report, "--no-profile"
        )

        expect(status.exitstatus).to eq(0), stderr
        examples = JSON.parse(File.read(report)).fetch("examples")
        names = examples.map { |example| example.fetch("full_description") }
        expect(names).to include(a_string_including("fixture corpus scan"))
        expect(names).not_to include(a_string_including("PR base corpus scan"))
      end

      { "pass" => 0, "regression" => 1, "error" => 2 }.each do |outcome, code|
        context "when the measurement reports #{outcome}" do
          let(:outcome) { outcome }

          it "exits with #{code}" do
            stdout, stderr, status = result

            expect(status.exitstatus).to eq(code), stdout + stderr
            expect(stdout).to include("2 examples")
          end
        end
      end
    end
  end

  describe ".sample" do
    let(:status) { instance_double(Process::Status, success?: true) }
    let(:document) do
      JSON.generate("elapsed" => 1.0, "served_by" => "native", "results" => 30,
                    "code_root" => Fontist.root_path.to_s,
                    "batch_contract" => true)
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

    it "returns batch loss as a valid measurement for regression comparison" do
      broken = JSON.parse(document).merge("batch_contract" => false)
      allow(Open3).to receive(:capture3).and_return(
        [JSON.generate(broken), "  125952 maximum resident set size\n", status],
      )

      expect(described_class.sample("native", "validator"))
        .to include("batch_contract" => false, "served_by" => "native")
    end

    it "keeps missing engine proof an error even when batching is lost" do
      broken = JSON.parse(document).merge("batch_contract" => false,
                                          "served_by" => "")
      allow(Open3).to receive(:capture3).and_return(
        [JSON.generate(broken), "", status],
      )

      expect do
        described_class.sample("native", "validator")
      end.to raise_error(described_class::Error, /did not serve/)
    end

    it "rejects a malformed batch contract" do
      broken = JSON.parse(document).merge("batch_contract" => "unknown")
      allow(Open3).to receive(:capture3).and_return(
        [JSON.generate(broken), "", status],
      )

      expect do
        described_class.sample("native", "validator")
      end.to raise_error(described_class::Error, /invalid batch contract/)
    end

    it "rejects a child that fell back to Ruby" do
      allow(Open3).to receive(:capture3).and_return(
        [document.sub("native", "ruby"), "", status],
      )

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /did not serve/)
    end

    it "rejects a malformed result count as a measurement error" do
      broken = JSON.parse(document).merge("results" => "thirty")
      allow(Open3).to receive(:capture3).and_return(
        [JSON.generate(broken), "", status],
      )

      expect do
        described_class.sample("native", "index")
      end.to raise_error(described_class::Error, /nonempty scan/)
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

  describe "lost validator batching" do
    let(:checkout) { Dir.mktmpdir("fontist-perf-per-file") }

    after { FileUtils.remove_entry(checkout) }

    it "reports a real per-file mutant as regression exit one" do
      %w[lib Gemfile Gemfile.lock fontist.gemspec].each do |path|
        FileUtils.cp_r(Fontist.root_path.join(path), checkout)
      end
      validator = File.join(checkout, "lib/fontist/validator.rb")
      original = File.read(validator)
      mutant = original.sub("def scan_results(paths)\n",
                            "def scan_results(paths)\n      " \
                            "return paths.to_h { |path| [path, nil] }\n")
      expect(mutant).not_to eq(original)
      File.write(validator, mutant)
      driver = File.join(checkout, "gate.rb")
      File.write(driver, <<~RUBY)
        require #{File.join(Fontist.root_path, 'spec/support/performance.rb').inspect}
        begin
          original_stdout = $stdout
          $stdout = $stderr
          measurement = ScanPathPerformance.measure("validator")
          $stdout = original_stdout
          puts JSON.generate(measurement)
          # RSS and the equal-time baseline are controlled classification inputs.
          # The mutant's engine, results and batch contract are measured above.
          sampler = lambda do |_, _, **options|
            sample = measurement.merge("rss" => 100.0)
            if options.fetch(:checkout) != #{checkout.inspect}
              sample = sample.merge("batch_contract" => true)
            end
            sample
          end
          gate = ScanPathPerformance::BaseGate.new(
            #{Fontist.root_path.to_s.inspect}, checkout: #{checkout.inspect},
            sampler: sampler
          )
          exit(gate.passes?("validator") ? 0 : 1)
        rescue StandardError, LoadError => e
          warn e.message
          exit 2
        end
      RUBY
      home = File.join(checkout, "home")
      FileUtils.mkdir_p(home)
      stdout, stderr, status = Open3.capture3(
        { "FONTIST_PERF_BASE" => nil, "FONTIST_PERF_TIER" => nil,
          "FONTISAN_ENGINE" => "ruby", "FONTISAN_ENGINE_STRICT" => "1",
          "FONTIST_PATH" => home,
          "FONTIST_PERF_CORPUS" => described_class::CORPUS,
          "BUNDLE_GEMFILE" => File.join(checkout, "Gemfile") },
        RbConfig.ruby, "-rbundler/setup", "-I#{checkout}/lib", driver
      )

      expect(status.exitstatus).to eq(1), stdout + stderr
      measured = JSON.parse(stdout.lines.first)
      expect(measured).to include(
        "served_by" => "ruby", "results" => be_positive,
        "batch_contract" => false, "code_root" => File.realpath(checkout)
      )
      expect(stdout).to include("batch_contract=false", "time=1.0 peak_rss=1.0")
      expect(stderr).not_to include("did not serve")
    end
  end

  describe "shared Fontist delay" do
    let(:delayed_checkout) { Dir.mktmpdir("fontist-perf-delay") }
    let(:reference) { described_class.sample("ruby", "validator") }
    let(:base_gate) do
      described_class::BaseGate.new(
        Fontist.root_path.to_s, checkout: delayed_checkout, output: output
      )
    end

    after { FileUtils.remove_entry(delayed_checkout) }

    before do
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
    rescue StandardError, LoadError
      RSpec.configuration.failure_exit_code = 2
      raise
    end

    it "fails comparison with unchanged code using only Ruby",
       :scan_path_base_gate do
      expect(base_gate.passes?("validator")).to be(false), output.string
    rescue StandardError, LoadError
      RSpec.configuration.failure_exit_code = 2
      raise
    end

    it "passes the tier floor despite the shared delay", :scan_path_gate do
      delayed_sampler = lambda do |tier, workload|
        described_class.sample(tier, workload, checkout: delayed_checkout)
      end
      tier_gate = described_class::Gate.new(
        ENV.fetch("FONTIST_PERF_TIER"), sampler: delayed_sampler, output: output
      )
      expect(tier_gate.passes?("validator")).to be(true), output.string
    rescue StandardError, LoadError
      RSpec.configuration.failure_exit_code = 2
      raise
    end
  end
end

RSpec.describe "Performance gate publication" do
  it "reports missing published engines on the PR for its exact head" do
    workflow = YAML.load_file(".github/workflows/perf-gate.yml")
    job = workflow.fetch("jobs")["report-engine-availability"]

    expect(job).not_to be_nil,
                       "missing engines are only reported in CI logs"
    expect(job.fetch("permissions")).to include("pull-requests" => "write")
    group = "scan-path-publication-" \
            "${{ github.event.pull_request.number }}"
    expect(job.fetch("concurrency")).to include(
      "group" => group,
      "cancel-in-progress" => false,
    )
    report = job.fetch("steps").find do |step|
      step["name"] == "Report published engines on the PR"
    end
    expect(report.fetch("env")).to include(
      "FONTIST_PERF_HEAD" => "${{ github.event.pull_request.head.sha }}",
      "FONTIST_PERF_COMMENT_AUTHOR" => "github-actions[bot]",
    )
    expect(report.fetch("run")).to include("spec/support/performance.rb",
                                           "--publish")
  end

  it "runs the report CLI without loading optional benchmark gems" do
    Tempfile.create(["fontist-report-bootstrap", ".rb"]) do |file|
      file.write(<<~RUBY)
        module MissingBenchmarkGems
          def require(name)
            if %w[rspec-benchmark benchmark-perf].include?(name)
              raise LoadError, "optional benchmark gem unavailable"
            end
            super
          end
        end
        Kernel.prepend(MissingBenchmarkGems)
      RUBY
      file.flush
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby, "-r", file.path, "spec/support/performance.rb",
        "--report", "--help"
      )

      expect(status.exitstatus).to eq(0), stdout + stderr
      expect(stdout).to include("--publish")
    end
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

  it "creates a marked PR comment when no owned publication exists" do
    success = instance_double(Process::Status, success?: true)
    expect(Open3).to receive(:capture3).exactly(3).times do |*args|
      case args
      when ["gh", "api", "user", "--jq", ".login"]
        ["ci-bot", "", success]
      when ["gh", "api", "--paginate", "--slurp",
            "repos/fontist/fontist/issues/552/comments"]
        ["[]", "", success]
      else
        expect(args.first(7)).to eq ["gh", "pr", "comment", "552", "--repo",
                                     "fontist/fontist", "--body-file"]
        expect(File.read(args.last)).to eq report.to_markdown
        ["https://github.com/fontist/fontist/pull/552#issuecomment-1", "",
         success]
      end
    end

    expect(described_class.publish(report, "fontist/fontist", "552"))
      .to include("issuecomment-1")
  end

  it "updates the owned marked comment on repeated publication" do
    success = instance_double(Process::Status, success?: true)
    created_comment = {
      "id" => 41, "user" => { "login" => "ci-bot" },
      "body" => "<!-- fontist-scan-path-publication -->\nold report"
    }
    lookup_count = 0
    create_count = 0
    patch_count = 0
    allow(Open3).to receive(:capture3) do |*args|
      case args
      when ["gh", "api", "user", "--jq", ".login"]
        ["ci-bot", "", success]
      when ["gh", "api", "--paginate", "--slurp",
            "repos/fontist/fontist/issues/552/comments"]
        lookup_count += 1
        comments = lookup_count == 1 ? [] : [[created_comment]]
        [JSON.generate(comments), "", success]
      else
        case args.first(6)
        when ["gh", "pr", "comment", "552", "--repo", "fontist/fontist"]
          create_count += 1
          expect(File.read(args.last)).to eq report.to_markdown
          ["created", "", success]
        when ["gh", "api", "--method", "PATCH",
              "repos/fontist/fontist/issues/comments/41", "--input"]
          patch_count += 1
          expect(JSON.parse(File.read(args.last))).to eq(
            "body" => report.to_markdown,
          )
          ["updated", "", success]
        else
          raise "unexpected command: #{args.inspect}"
        end
      end
    end

    2.times { described_class.publish(report, "fontist/fontist", "552") }
    expect(lookup_count).to eq 2
    expect(create_count).to eq 1
    expect(patch_count).to eq 1
  end

  it "uses an explicitly configured CI comment author" do
    success = instance_double(Process::Status, success?: true)
    comments = [
      [{ "id" => 40, "user" => { "login" => "other-bot" },
         "body" => "unrelated" }],
      [{ "id" => 41, "user" => { "login" => "github-actions[bot]" },
         "body" => "<!-- fontist-scan-path-publication -->\nold report" }],
    ]
    expect(Open3).not_to receive(:capture3).with("gh", "api", "user", "--jq",
                                                 ".login")
    expect(Open3).to receive(:capture3).with(
      "gh", "api", "--paginate", "--slurp",
      "repos/fontist/fontist/issues/552/comments"
    ).and_return([JSON.generate(comments), "", success])
    expect(Open3).to receive(:capture3) do |*args|
      expect(args.first(6)).to eq ["gh", "api", "--method", "PATCH",
                                   "repos/fontist/fontist/issues/comments/41",
                                   "--input"]
      ["updated", "", success]
    end

    described_class.publish(report, "fontist/fontist", "552",
                            author: "github-actions[bot]")
  end

  it "does not update a marked comment owned by another actor" do
    success = instance_double(Process::Status, success?: true)
    comments = [
      { "id" => 41, "user" => { "login" => "human" },
        "body" => "<!-- fontist-scan-path-publication -->\nprivate note" },
    ]
    allow(Open3).to receive(:capture3) do |*args|
      case args
      when ["gh", "api", "user", "--jq", ".login"]
        ["ci-bot", "", success]
      when ["gh", "api", "--paginate", "--slurp",
            "repos/fontist/fontist/issues/552/comments"]
        [JSON.generate([comments]), "", success]
      else
        expect(args.first(7)).to eq ["gh", "pr", "comment", "552", "--repo",
                                     "fontist/fontist", "--body-file"]
        expect(File.read(args.last)).to eq report.to_markdown
        ["created", "", success]
      end
    end

    described_class.publish(report, "fontist/fontist", "552")
  end

  it "does not treat a marker embedded in unrelated comment text as a match" do
    success = instance_double(Process::Status, success?: true)
    comments = [
      { "id" => 41, "user" => { "login" => "ci-bot" },
        "body" => "An unrelated note mentions " \
                  "<!-- fontist-scan-path-publication -->" },
    ]
    allow(Open3).to receive(:capture3) do |*args|
      case args
      when ["gh", "api", "user", "--jq", ".login"]
        ["ci-bot", "", success]
      when ["gh", "api", "--paginate", "--slurp",
            "repos/fontist/fontist/issues/552/comments"]
        [JSON.generate([comments]), "", success]
      else
        expect(args.first(7)).to eq ["gh", "pr", "comment", "552", "--repo",
                                     "fontist/fontist", "--body-file"]
        ["created", "", success]
      end
    end

    described_class.publish(report, "fontist/fontist", "552")
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
