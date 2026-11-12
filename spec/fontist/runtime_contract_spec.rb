require "spec_helper"

# Runtime contract (fontist#548): no fork, no Marshal, and every Parallel
# pool is a thread pool capped by a local variable assigned from
# `[..., N].min` in the same method, immediately before the call. The guard
# covers every file under lib/fontist.
module RuntimeContractCheck
  CAPPED = /\A\[[^\]\n]*,\s*\d+\s*\]\.min\b/
  CALL = /Parallel\.(?!processor_count\b)\w+/

  module_function

  def code_of(source)
    source.lines.reject { |l| l.strip.start_with?("#") }.join
  end

  # [offset, argument text] for every Parallel.<method> call, with or
  # without parentheses.
  def parallel_calls(source)
    source.to_enum(:scan, CALL).map do
      finish = Regexp.last_match.end(0)
      [Regexp.last_match.begin(0), arguments_at(source, finish)]
    end
  end

  def arguments_at(source, start)
    return paren_args(source, start + 1) if source[start] == "("

    line_args(source, start)
  end

  def paren_args(source, start)
    depth = 1
    idx = start
    while idx < source.length && depth.positive?
      depth += 1 if source[idx] == "("
      depth -= 1 if source[idx] == ")"
      idx += 1
    end
    source[start...idx]
  end

  # Parenthesis-less call: the rest of the line, following continuations.
  def line_args(source, start)
    text = +""
    source[start..].each_line do |line|
      text << line
      break unless line.rstrip.end_with?(",", "\\")
    end
    text
  end

  # The last assignment to var before offset, within the enclosing method.
  def last_assignment(source, offset, var)
    before = source[0...offset]
    defs = before.rindex(/^\s*def\s/)
    scope = defs ? before[defs..] : before
    scope.scan(/\b#{Regexp.escape(var)}\s*(?:\|\|)?=(?!=)\s*(.*)/).flatten.last
  end

  def violations(raw_source)
    source = code_of(raw_source)
    banned_violations(source) +
      parallel_calls(source).filter_map do |offset, args|
        pool_violation(source, offset, args)
      end
  end

  def banned_violations(source)
    { "Marshal" => /\bMarshal\b/, "fork" => /\b(Process\.)?fork\b/,
      "in_processes" => /\bin_processes\b/ }
      .select { |_, pattern| source.match?(pattern) }.keys
  end

  def pool_violation(source, offset, args)
    match = args.match(/\bin_threads:\s*([a-z_]\w*)\s*(?:,|\)|\bdo\b|\{|\z)/)
    return "Parallel call without capped in_threads: #{args.strip}" unless match

    rhs = last_assignment(source, offset, match[1])
    return if rhs&.match?(CAPPED)

    "in_threads: #{match[1]} is not assigned from [..., N].min " \
      "in the enclosing method before the call"
  end
end

RSpec.describe "Runtime contract" do
  lib_files = Dir.glob(File.join(Fontist.root_path, "lib", "fontist", "**",
                                 "*.rb"))

  it "finds lib files to scan" do
    expect(lib_files).not_to be_empty
  end

  lib_files.each do |file|
    relative = file.sub("#{Fontist.root_path}/", "")

    it "#{relative} honours the runtime contract" do
      expect(RuntimeContractCheck.violations(File.read(file))).to be_empty
    end
  end

  describe "the checker" do
    def violations(source)
      RuntimeContractCheck.violations(source)
    end

    it "accepts a capped local in the same method" do
      expect(violations(<<~RUBY)).to be_empty
        def run(paths)
          workers = [Parallel.processor_count, 8].min
          Parallel.map(paths, in_threads: workers) { |p| p }
        end
      RUBY
    end

    it "accepts a capped parenthesis-less call" do
      expect(violations(<<~RUBY)).to be_empty
        def run(paths)
          workers = [Parallel.processor_count, 8].min
          Parallel.map paths, in_threads: workers do |p|
            p
          end
        end
      RUBY
    end

    it "rejects a parenthesis-less call without in_threads" do
      expect(violations(<<~RUBY)).not_to be_empty
        def run(items)
          Parallel.map items do |item|
            item
          end
        end
      RUBY
    end

    it "rejects a parenthesis-less call with a raw core count" do
      expect(violations(<<~RUBY)).not_to be_empty
        def run(items)
          Parallel.map items, in_threads: Parallel.processor_count do |i|
            i
          end
        end
      RUBY
    end

    it "rejects a cap assigned in a different method" do
      expect(violations(<<~RUBY)).not_to be_empty
        def capped
          workers = [Parallel.processor_count, 8].min
        end

        def run(items)
          Parallel.map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "rejects a cap that is overwritten before the call" do
      expect(violations(<<~RUBY)).not_to be_empty
        def run(items)
          workers = [Parallel.processor_count, 8].min
          workers = Parallel.processor_count
          Parallel.map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "rejects Marshal, fork and in_processes" do
      expect(violations("Marshal.dump(1)")).not_to be_empty
      expect(violations("Process.fork { }")).not_to be_empty
      expect(violations("Parallel.map(a, in_processes: 2) { }")).not_to be_empty
    end
  end
end
