require "spec_helper"
require "ripper"

# Runtime contract (fontist#548): no fork, no Marshal, and every Parallel
# pool is a thread pool capped by a local variable assigned from
# `[..., N].min` in the same method, immediately before the call. The guard
# covers every file under lib/fontist.
module RuntimeContractCheck
  CAPPED = /\A\[[^\]\n]*,\s*\d+\s*\]\.min\s*(?:#.*)?\z/
  CALL = /(?:\.|::)(?!processor_count\b)\w+/
  ALIAS = /\b([A-Za-z_]\w*)\s*=\s*(?:::)?Parallel\b(?!\s*(?:\.|::))/

  module_function

  def code_of(source)
    source.lines.reject { |l| l.strip.start_with?("#") }.join
  end

  # [offset, argument text] for every Parallel method call, using . or ::,
  # with or without parentheses.
  def parallel_calls(source)
    aliases = source.scan(ALIAS).flatten
    receivers = Regexp.union(["Parallel", *aliases])
    source.to_enum(:scan, /\b#{receivers}#{CALL}/).map do
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

  ASSIGN_OPS = '(?:\\|\\||&&|\\*\\*|<<|>>|[-+*\\/%|&^])?'.freeze

  def syntax_nodes(node)
    return [] unless node.is_a?(Array)

    [node] + node.flat_map { |child| syntax_nodes(child) }
  end

  BLOCK_TYPES = %i[brace_block do_block].freeze

  def syntax_tokens(node)
    syntax_nodes(node).select { |child| child[0].to_s.start_with?("@") }
  end

  def token_offset(source, token)
    line, column = token[2]
    lines = source.lines
    lines.take(line - 1).sum(&:length) +
      lines[line - 1].byteslice(0, column).length
  end

  def parameter_offset(source, block, var)
    syntax_tokens(block[1]).filter_map do |token|
      token_offset(source, token) if token[0] == :@ident && token[1] == var
    end.max
  end

  def block_finish(source, block)
    syntax_tokens(block[2]).map do |token|
      token_offset(source, token) + token[1].length
    end.max
  end

  def block_shadow(source, block, offset, var)
    start = parameter_offset(source, block, var)
    finish = block_finish(source, block)
    return unless start && finish

    start if start < offset && offset < finish
  end

  # A block parameter creates a different local binding. Only consider the
  # enclosing block: a closed sibling block does not shadow the outer cap.
  def shadowing_offset(source, offset, var)
    blocks = syntax_nodes(Ripper.sexp(source)).select do |node|
      BLOCK_TYPES.include?(node[0])
    end
    blocks.filter_map { |block| block_shadow(source, block, offset, var) }.max
  end

  # The right-hand side of the last assignment to var before offset, within
  # the enclosing method. Compound assignments (`+=`, `*=`, `||=`, ...)
  # return a marker that never matches CAPPED, as they change the value.
  def last_assignment(source, offset, var)
    before = source[0...offset]
    defs = before.rindex(/^\s*def\s/)
    start = [defs || 0, shadowing_offset(source, offset, var) || 0].max
    scope = before[start..]
    pattern = /\b#{Regexp.escape(var)}\s*(#{ASSIGN_OPS})=(?![=~])\s*(.*)/
    op, rhs = scope.scan(pattern).last
    return if op.nil?

    op.empty? ? rhs : "#{op}= #{rhs}"
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

    it "rejects a cap changed by a compound assignment" do
      %w[*= += ||= <<= -=].each do |op|
        expect(violations(<<~RUBY)).not_to be_empty, op
          def run(items)
            workers = [Parallel.processor_count, 8].min
            workers #{op} 100
            Parallel.map(items, in_threads: workers) { |i| i }
          end
        RUBY
      end
    end

    it "rejects an expression that increases the cap" do
      expect(violations(<<~RUBY)).not_to be_empty
        def run(items)
          workers = [Parallel.processor_count, 8].min * 100
          Parallel.map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "rejects uncapped pools for any Parallel operation" do
      %w[map each each_with_index flat_map].each do |operation|
        source = "Parallel.#{operation}(items) { |i| i }"
        expect(violations(source)).not_to be_empty
      end
    end

    %w[map each].each do |operation|
      it "rejects uncapped Parallel::#{operation} calls" do
        source = "Parallel::#{operation}(items) { |i| i }"
        expect(violations(source)).not_to be_empty
      end
    end

    it "accepts a capped local with double-colon call syntax" do
      expect(violations(<<~RUBY)).to be_empty
        def run(items)
          workers = [Parallel::processor_count, 8].min
          Parallel::map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "ignores comparisons of the capped variable" do
      expect(violations(<<~RUBY)).to be_empty
        def run(items)
          workers = [Parallel.processor_count, 8].min
          return if workers <= 1 || workers == 3 || workers != 4
          Parallel.map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "rejects an uncapped call through a Parallel alias" do
      expect(violations(<<~RUBY)).not_to be_empty
        module Fontist
          P = Parallel
          def self.run(items)
            P.map(items) { |i| i }
          end
        end
      RUBY
    end

    it "accepts a capped call through a Parallel alias" do
      expect(violations(<<~RUBY)).to be_empty
        P = Parallel
        def run(items)
          workers = [P.processor_count, 8].min
          P.map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "does not treat the result of a Parallel call as an alias" do
      expect(violations(<<~RUBY)).to be_empty
        def run(items)
          workers = [Parallel.processor_count, 8].min
          results = Parallel.map(items, in_threads: workers) { |i| i }
          results.each { |i| puts i }
        end
      RUBY
    end

    { "brace" => ["{", "}"], "do" => ["do", "end"] }.each do |kind, ends|
      it "rejects a capped local shadowed by a #{kind} block parameter" do
        expect(violations(<<~RUBY)).not_to be_empty
          def run(items)
            workers = [Parallel.processor_count, 8].min
            items.each #{ends.first} |workers|
              Parallel.map(items, in_threads: workers) { |i| i }
            #{ends.last}
          end
        RUBY
      end
    end

    it "accepts an outer cap after a shadowing block has ended" do
      expect(violations(<<~RUBY)).to be_empty
        def run(items)
          workers = [Parallel.processor_count, 8].min
          items.each { |workers| puts workers }
          Parallel.map(items, in_threads: workers) { |i| i }
        end
      RUBY
    end

    it "accepts a block parameter capped again before the pool call" do
      expect(violations(<<~RUBY)).to be_empty
        def run(items)
          items.each do |workers|
            workers = [Parallel.processor_count, 8].min
            Parallel.map(items, in_threads: workers) { |i| i }
          end
        end
      RUBY
    end

    it "rejects Marshal, fork and in_processes" do
      expect(violations("Marshal.dump(1)")).not_to be_empty
      expect(violations("Process.fork { }")).not_to be_empty
      expect(violations("fork { }")).not_to be_empty
      expect(violations("Parallel.map(a, in_processes: 2) { }")).not_to be_empty
    end
  end
end
