require "bundler"
require "json"
require "net/http"
require "open3"
require "optparse"
require "rubygems/platform"
require "tempfile"

module ScanPathPublication
  class Error < StandardError; end

  class Report
    TARGETS = {
      "Linux x86_64" => "x86_64-linux-gnu",
      "macOS arm64" => "arm64-darwin",
      "macOS x86_64" => "x86_64-darwin",
    }.freeze

    def initialize(expected_head:, remote_head:, version:, platforms:)
      @expected_head = expected_head
      @remote_head = remote_head
      @version = version
      @platforms = platforms
    end

    def current?
      @expected_head == @remote_head
    end

    def missing_platforms
      TARGETS.reject do |_, target|
        @platforms.any? { |platform| matches?(platform, target) }
      end
    end

    def exit_status
      current? && missing_platforms.empty? ? 0 : 2
    end

    def to_markdown
      <<~MARKDOWN
        <!-- fontist-scan-path-publication -->
        **Scan path performance gate status**

        #{head_message}

        #{availability_message}

        RubyGems reports these platforms for fontisan #{@version}: #{@platforms.join(', ')}.
        [Published version metadata](https://rubygems.org/api/v1/versions/fontisan.json)
      MARKDOWN
    end

    private

    def matches?(platform, target)
      return false if platform == "ruby"

      target = Gem::Platform.new(target)
      candidate = Gem::Platform.new(platform)
      candidate.os == target.os && candidate.cpu == target.cpu &&
        (target.os != "linux" || glibc?(candidate))
    end

    def glibc?(platform)
      platform.version.nil? || platform.version.start_with?("gnu")
    end

    def head_message
      if current?
        return "PR head matches the checked commit `#{@expected_head}`."
      end

      "ERROR: PR head `#{@remote_head}` is stale; " \
        "the checked commit is `#{@expected_head}`. " \
        "CI on the old head does not validate the checked commit."
    end

    def availability_message
      return missing_message unless missing_platforms.empty?

      "All required platform gems are published. " \
        "Strict tier checks still verify the installed engines."
    end

    def missing_message
      missing = missing_platforms.map do |name, platform|
        "- #{name}: `#{platform}` (native and FFI)"
      end
      <<~MARKDOWN
        Missing published binaries for **fontisan #{@version}**:

        #{missing.join("\n")}

        The strict native/FFI cells exit **2 (error)**. Hassan's D4 platform-gem release is required; the jobs will not build engines from source.
      MARKDOWN
    end
  end

  def self.command(*args)
    stdout, stderr, status = Open3.capture3(*args)
    raise Error, "#{args.first} failed: #{stderr}" unless status.success?

    stdout.strip
  end

  def self.collect(repository, number, expected_head: nil)
    expected_head ||= command("git", "rev-parse", "HEAD")
    version = locked_version
    Report.new(expected_head: expected_head,
               remote_head: remote_head(repository, number),
               version: version, platforms: published_platforms(version))
  end

  def self.remote_head(repository, number)
    JSON.parse(command("gh", "pr", "view", number,
                       "--repo", repository, "--json", "headRefOid"))
      .fetch("headRefOid")
  end

  def self.locked_version
    spec = Bundler::LockfileParser.new(File.read("Gemfile.lock"))
      .specs.find { |entry| entry.name == "fontisan" }
    raise Error, "fontisan version missing from Gemfile.lock" unless spec

    spec.version.to_s
  end

  def self.metadata
    uri = URI("https://rubygems.org/api/v1/versions/fontisan.json")
    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "RubyGems metadata request failed: HTTP #{response.code}"
    end

    JSON.parse(response.body)
  end

  def self.published_platforms(version)
    metadata.select { |entry| entry.fetch("number") == version }
      .map { |entry| entry.fetch("platform") }.uniq.sort
  end

  def self.publish(report, repository, number)
    Tempfile.create(["fontist-perf-report", ".md"]) do |file|
      file.write(report.to_markdown)
      file.flush
      command("gh", "pr", "comment", number, "--repo", repository,
              "--body-file", file.path)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    publish = false
    OptionParser.new do |options|
      options.on("--publish") { publish = true }
    end.parse!
    repository, number = ARGV
    unless repository && number
      raise ScanPathPublication::Error,
            "expected OWNER/REPO PR_NUMBER [--publish]"
    end

    report = ScanPathPublication.collect(repository, number,
                                         expected_head:
                                           ENV.fetch("FONTIST_PERF_HEAD", nil))
    puts report.to_markdown
    puts ScanPathPublication.publish(report, repository, number) if publish
    exit report.exit_status
  rescue StandardError, LoadError => e
    warn "ERROR: #{e.message}"
    exit 2
  end
end
