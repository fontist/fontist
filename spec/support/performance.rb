require "rspec-benchmark"
require "benchmark-perf"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"
require "bundler"

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include RSpec::Benchmark::Matchers
    # Timing gates are opt-in; ordinary specs still exercise the gate's rules.
    base = !ENV.fetch("FONTIST_PERF_BASE", "").empty?
    enabled = ENV["FONTIST_PERF_TIER"] || base
    config.error_exit_code = 2 if enabled
    unless ENV["FONTIST_PERF_TIER"]
      config.filter_run_excluding scan_path_gate: true
    end
    unless enabled && (base || ENV["GITHUB_EVENT_NAME"] == "pull_request")
      config.filter_run_excluding scan_path_base_gate: true
    end
  end
end

RSpec::Benchmark.configure do |config|
  config.run_in_subprocess = true
end

# Each sample starts a fresh Ruby process: neither cached scan rows nor an
# earlier tier's allocations can contaminate elapsed time or peak RSS.
module ScanPathPerformance
  class Error < StandardError; end

  ROOT = File.expand_path("../..", __dir__).freeze
  CORPUS = File.join(ROOT, "spec/fixtures/fonts").freeze

  class Comparison
    def initialize(reference:, candidate:, sampler:, time_limit:, output:)
      @reference = reference
      @candidate = candidate
      @sampler = sampler
      @time_limit = time_limit
      @output = output
    end

    def passes?(workload)
      2.times do |attempt|
        ratios = measure_ratios(workload, attempt)
        report(workload, ratios, attempt)
        return true if within_floor?(ratios)
      end
      false
    end

    private

    def measure_ratios(workload, attempt)
      samples = collect_samples(workload, attempt)
      %w[elapsed rss].to_h do |metric|
        reference = median(samples.fetch(@reference), metric)
        [metric, median(samples.fetch(@candidate), metric) / reference]
      end
    end

    def collect_samples(workload, attempt)
      samples = { @reference => [], @candidate => [] }
      5.times do |round|
        order = [@reference, @candidate]
        order.reverse! if ((attempt * 5) + round).odd?
        order.each do |tier|
          samples.fetch(tier) << @sampler.call(tier, workload)
        end
      end
      samples
    end

    def within_floor?(ratios)
      ratios.fetch("elapsed") <= @time_limit && ratios.fetch("rss") <= 1.03
    end

    def report(workload, ratios, attempt)
      @output.puts "#{workload} #{@candidate}/#{@reference} medians: " \
                   "time=#{ratios.fetch('elapsed').round(4)} " \
                   "peak_rss=#{ratios.fetch('rss').round(4)} " \
                   "(attempt #{attempt + 1})"
    end

    def median(samples, metric)
      values = samples.map { |sample| sample.fetch(metric) }
      valid = values.all? do |value|
        value.is_a?(Numeric) && value.finite? && value.positive?
      end
      raise Error, "invalid #{metric}: #{values.inspect}" unless valid

      values.sort.fetch(2).to_f
    end
  end

  class Gate < Comparison
    def initialize(tier, sampler: ScanPathPerformance.method(:sample),
                   output: $stdout)
      unless %w[native ffi].include?(tier)
        raise Error, "force native or ffi, got #{tier.inspect}"
      end

      super(reference: "ruby", candidate: tier, sampler: sampler,
            time_limit: 1.0, output: output)
    end
  end

  class BaseGate < Comparison
    def initialize(base, checkout: ROOT,
                   sampler: ScanPathPerformance.method(:sample),
                   output: $stdout)
      raise Error, "missing PR base checkout" if base.to_s.empty?

      roots = { "base" => File.expand_path(base), "pr" => checkout }
      ruby_sampler = lambda do |side, workload|
        sampler.call("ruby", workload, checkout: roots.fetch(side),
                                       corpus: CORPUS)
      end
      super(reference: "base", candidate: "pr", sampler: ruby_sampler,
            time_limit: 1.15, output: output)
    end
  end

  def self.sample(tier, workload, checkout: ROOT, corpus: CORPUS)
    Dir.mktmpdir("fontist-perf") do |dir|
      stdout, stderr, status = capture_sample(tier, workload, checkout, corpus,
                                              dir)
      unless status.success?
        raise Error,
              "#{workload} #{tier} exited #{status.exitstatus}: #{stderr}"
      end

      parse_sample(stdout, tier, checkout).merge("rss" => peak_rss(stderr))
    end
  rescue JSON::ParserError, KeyError, SystemCallError => e
    raise Error, "#{workload} #{tier} measurement error: #{e.message}"
  end

  def self.capture_sample(tier, workload, checkout, corpus, home)
    checkout = File.expand_path(checkout)
    env = { "FONTISAN_ENGINE" => tier, "FONTISAN_ENGINE_STRICT" => "1",
            "FONTIST_PATH" => home, "LC_ALL" => "C",
            "FONTIST_PERF_CORPUS" => File.expand_path(corpus),
            "BUNDLE_GEMFILE" => File.join(checkout, "Gemfile"),
            "RUBYLIB" => nil, "RUBYOPT" => nil }
    flag = RUBY_PLATFORM.include?("darwin") ? "-l" : "-v"
    Bundler.with_unbundled_env do
      Open3.capture3(
        env, "/usr/bin/time", flag, RbConfig.ruby, "-rbundler/setup",
        "-I#{checkout}/lib", File.expand_path(__FILE__), "--sample", workload,
        chdir: checkout
      )
    end
  end

  def self.parse_sample(stdout, tier, checkout)
    result = JSON.parse(stdout)
    served = result.fetch("served_by") == tier
    unless served && result.fetch("results").positive?
      raise Error, "#{tier} did not serve a nonempty scan: #{result.inspect}"
    end

    unless result.fetch("code_root") == File.realpath(checkout)
      raise Error, "loaded fontist from wrong checkout: #{result.inspect}"
    end

    result
  end

  def self.peak_rss(stderr)
    # GNU time reports KiB; BSD time reports bytes. Only ratios are gated.
    linux = stderr[/Maximum resident set size \(kbytes\):\s*(\d+)/, 1]
    macos = stderr[/^\s*(\d+)\s+maximum resident set size\s*$/, 1]
    value = linux ? linux.to_i * 1024 : macos.to_i
    raise Error, "missing peak RSS from /usr/bin/time" unless value.positive?

    value
  end

  def self.measure(workload)
    require "fontist"
    require "fontisan"

    prepare_scan
    paths = fixture_paths
    operation = operation_for(workload, paths)
    count = nil
    timing = Benchmark::Perf.cpu(repeat: 1, warmup: 0, subprocess: false) do
      count = operation.call.size
    end
    { "elapsed" => timing.avg, "results" => count,
      "served_by" => Fontisan::Engine.served_by(:scan).to_s,
      "code_root" => Fontist.root_path.realpath.to_s }
  end

  def self.prepare_scan
    Fontist.ui.level = :error
    Fontist.interactive = false
    Fontisan::Engine.reset!
    Fontisan::Engine.setup!
  end

  def self.fixture_paths
    pattern = File.join(ENV.fetch("FONTIST_PERF_CORPUS", CORPUS), "**/*")
    extensions = %w[.ttf .otf .ttc .otc .dfont .woff .woff2]
    paths = Dir.glob(pattern).select do |path|
      File.file?(path) && extensions.include?(File.extname(path).downcase)
    end
    raise Error, "empty fixture font corpus" if paths.empty?

    paths
  end

  def self.operation_for(workload, paths)
    case workload
    when "index"
      index = Fontist::SystemIndexFontCollection.from_file(
        path: Fontist.system_index_path, paths_loader: -> { paths },
      )
      -> { index.rebuild.fonts }
    when "validator"
      validator = Fontist::Validator.new
      # Replace discovery only; validate_all still scans every miss.
      validator.define_singleton_method(:scan_font_paths) { paths }
      -> { validator.validate_all.results }
    else
      raise Error, "unknown scan workload: #{workload.inspect}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    unless ARGV.shift == "--sample"
      raise ScanPathPerformance::Error,
            "expected --sample index|validator"
    end

    # Fontist diagnostics go to stderr; stdout is a single measurement document.
    original_stdout = $stdout
    $stdout = $stderr
    result = ScanPathPerformance.measure(ARGV.fetch(0))
    original_stdout.puts JSON.generate(result)
  rescue StandardError, LoadError => e
    warn "#{e.class}: #{e.message} (#{RUBY_PLATFORM})"
    exit 2
  end
end
