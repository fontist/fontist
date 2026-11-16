require "spec_helper"
require "ripper"

# Runtime contract (fontist#548): no processes or Marshal, and every Parallel
# pool uses a local assigned from an array with a fixed positive bound and .min.
# Parse Ruby so comments/literals cannot trigger the guard or supply a fake cap.
class RuntimeContractCheck
  VISITORS = {
    visit_call: %i[call command_call fcall vcall command method_add_arg],
    visit_scope: %i[def defs class module sclass],
    visit_block: %i[brace_block do_block],
    visit_for: %i[for],
    visit_branches: %i[if unless elsif if_mod unless_mod case when rescue
                       rescue_mod while until while_mod until_mod],
    visit_assignment: %i[assign massign opassign],
  }.flat_map do |visitor, types|
    types.map do |type|
      [type, visitor]
    end
  end.to_h.freeze

  def self.violations(source)
    tree = Ripper.sexp(source)
    return ["Cannot parse Ruby source"] unless tree

    new.check(tree)
  end

  def initialize
    @violations = []
  end

  def check(tree)
    visit(tree, {})
    @violations.uniq
  end

  private

  def nodes(tree)
    return [] unless tree.is_a?(Array)

    [tree] + tree.flat_map { |child| nodes(child) }
  end

  def variable(node)
    return unless node.is_a?(Array)
    return node.dig(2, 1) if node[0] == :const_path_ref

    return unless %i[var_ref var_field const_ref
                     top_const_ref].include?(node[0])

    node.dig(1, 1)
  end

  def call_parts(node)
    case node&.first
    when :method_add_arg
      receiver, name, = call_parts(node[1])
      [receiver, name, node[2]]
    when :call, :command_call
      [node[1], node.dig(3, 1), node[4]]
    when :fcall, :vcall, :command
      [nil, node.dig(1, 1), node[2]]
    end
  end

  def arguments(node)
    return [] unless node.is_a?(Array)
    return arguments(node[1]) if node[0] == :arg_paren

    node[0] == :args_add_block ? node[1] : []
  end

  def literal(node)
    case node&.first
    when :symbol_literal
      node.dig(1, 1, 1)
    when :string_literal
      content = node[1]
      content.dig(1, 1) if content.size == 2 &&
        content.dig(1, 0) == :@tstring_content
    end
  end

  def parallel?(node, locals)
    name = variable(node)
    return true if name == "Parallel" || (name && locals[name] == :parallel)

    receiver, method, args = call_parts(node)
    variable(receiver) == "Object" && method == "const_get" &&
      literal(arguments(args).first) == "Parallel"
  end

  def capped?(node)
    receiver, method, args = call_parts(node)
    return false unless method == "min" && no_arguments?(args) &&
      receiver&.first == :array

    Array(receiver[1]).any? { |element| positive_integer?(element) }
  end

  def positive_integer?(node)
    node.is_a?(Array) && node[0] == :@int && node[1].to_i.positive?
  end

  def no_arguments?(node)
    node.nil? || node == [:arg_paren, nil]
  end

  def visit(node, locals)
    return unless node.is_a?(Array)

    send(VISITORS.fetch(node[0], :visit_default), node, locals)
  end

  def visit_scope(node, locals)
    visit_children(node, locals.select { |name, _| name.match?(/\A[A-Z]/) })
  end

  def visit_default(node, locals)
    check_banned(node)
    visit_children(node, locals)
  end

  def visit_children(node, locals)
    node.each { |child| visit(child, locals) if child.is_a?(Array) }
  end

  def check_banned(node)
    @violations << "Marshal" if variable(node) == "Marshal"
    @violations << "in_processes" if keyword?(node, "in_processes")
  end

  def keyword?(node, name)
    node[0] == :assoc_new &&
      (node.dig(1, 1) == "#{name}:" || literal(node[1]) == name)
  end

  def assigned_names(node)
    nodes(node).filter_map do |child|
      variable(child) if child[0] == :var_field
    end
  end

  def binding_value(node, locals)
    return :parallel if parallel?(node, locals)

    :capped if capped?(node)
  end

  def visit_assignment(node, locals)
    # Inspect the RHS before updating bindings, including calls nested in it.
    visit_children(node, locals)
    names = assigned_names(node[1])
    value = binding_value(node[2], locals) if node[0] == :assign
    names.each { |name| locals.delete(name) }
    return unless node[0] == :assign && names.size == 1

    locals[names.first] = value
  end

  def visit_block(node, locals)
    shadowed = nodes(node[1]).filter_map do |child|
      child[1] if child[0] == :@ident
    end
    inner = locals.except(*shadowed)
    visit(node[2], inner)
    # A block may execute zero times; retain only unchanged outer bindings.
    locals.delete_if do |name, value|
      !shadowed.include?(name) && inner[name] != value
    end
  end

  def visit_branches(node, locals)
    # A conditional/loop need not execute. Each arm must stand on its own,
    # and a write in any arm invalidates an outer cap after the construct.
    outcomes = node.drop(1).map do |child|
      locals.dup.tap { |branch| visit(child, branch) }
    end
    locals.delete_if do |name, value|
      outcomes.any? do |branch|
        branch[name] != value
      end
    end
  end

  def visit_for(node, locals)
    assigned_names(node[1]).each { |name| locals.delete(name) }
    visit_branches(node, locals)
  end

  def visit_call(node, locals)
    receiver, method, args = call_parts(node)
    visit(receiver, locals)
    visit(args, locals)
    @violations << "fork" if method == "fork"
    if variable(receiver) == "Process" && method == "daemon"
      @violations << "Process.daemon"
    end
    return unless parallel?(receiver, locals)
    return if method == "processor_count"

    check_pool(args, locals)
  end

  def option_pairs(args)
    options = arguments(args).last
    case options&.first
    when :bare_assoc_hash then options[1]
    when :hash then options.dig(1, 1)
    else []
    end
  end

  def thread_value(args)
    pairs = option_pairs(args)
    return if pairs.any? { |pair| pair[0] == :assoc_splat }

    thread_option = pairs.reverse.find do |pair|
      keyword?(pair, "in_threads")
    end
    thread_option&.[](2)
  end

  def check_pool(args, locals)
    name = variable(thread_value(args))
    return if name&.match?(/\A[a-z_]/) && locals[name] == :capped

    @violations << "Parallel call without capped local in_threads"
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

    it "ignores comments and literal text" do
      expect(violations(<<~RUBY)).to be_empty
        x = 1 # Marshal is banned; do not fork
        message = 'do not fork here'
        pattern = /Marshal|fork|Parallel.map/
        text = <<~TEXT
          Marshal.dump(x); Process.fork; Parallel.map(items)
        TEXT
      RUBY
    end

    it "still checks executable string interpolation" do
      expect(violations("\"\#{Marshal.dump(1)}\"")).not_to be_empty
    end

    it "accepts a cap in either array position and across lines" do
      expect(violations(<<~RUBY)).to be_empty
        def run(items)
          workers = [
            8,
            Parallel.processor_count
          ].min # a fixed upper bound
          Parallel.map(items, in_threads: workers) { }
        end
      RUBY
    end

    it "rejects a cap overwritten by multiple assignment" do
      expect(violations(<<~RUBY)).not_to be_empty
        def run(items)
          workers = [Parallel.processor_count, 8].min
          workers, other = Parallel.processor_count, 1
          Parallel.map(items, in_threads: workers) { }
        end
      RUBY
    end

    it "rejects a cap borrowed from a sibling method on the same line" do
      expect(violations(<<~RUBY)).not_to be_empty
        def capped; workers = [Parallel.processor_count, 8].min; end
        def run(items); Parallel.map(items, in_threads: workers) { }; end
      RUBY
    end

    it "rejects an uncapped pool through a literal constant lookup" do
      source = "Object.const_get(:Parallel).map(items) { }"
      expect(violations(source)).not_to be_empty
    end

    it "rejects daemonized processes" do
      expect(violations("Process.daemon")).not_to be_empty
    end

    it "rejects invalid source instead of silently skipping it" do
      expect(violations("Parallel.map(")).to eq ["Cannot parse Ruby source"]
    end

    it "does not treat identifiers or symbols as banned calls" do
      expect(violations("fork = :Marshal; puts fork")).to be_empty
    end

    it "rejects qualified constants and string constant lookups" do
      ["::Parallel.map(items)", "Object::Parallel.map(items)",
       'Object.const_get("Parallel").map(items)',
       "::Marshal.dump(1)", "Object::Marshal.dump(1)"].each do |source|
        expect(violations(source)).not_to be_empty, source
      end
    end

    it "requires a local cap instead of inline or raw thread counts" do
      ["Parallel.processor_count", "[Parallel.processor_count, 8].min",
       "8"].each do |value|
        source = "Parallel.map(items, in_threads: #{value}) { }"
        expect(violations(source)).not_to be_empty, source
      end
    end

    it "does not borrow a nested call's thread option" do
      expect(violations(<<~RUBY)).not_to be_empty
        workers = [Parallel.processor_count, 8].min
        Parallel.map(fetch(items, in_threads: workers)) { }
      RUBY
    end

    it "rejects thread options overwritten by later keywords" do
      ["in_threads: Parallel.processor_count", "**options"].each do |suffix|
        expect(violations(<<~RUBY)).not_to be_empty
          workers = [Parallel.processor_count, 8].min
          Parallel.map(items, in_threads: workers, #{suffix}) { }
        RUBY
      end
    end

    it "rejects min with a comparator that could reverse the cap" do
      expect(violations(<<~RUBY)).not_to be_empty
        workers = [Parallel.processor_count, 8].min(&descending)
        Parallel.map(items, in_threads: workers) { }
      RUBY
    end

    it "does not borrow a cap from a conditional branch" do
      expect(violations(<<~RUBY)).not_to be_empty
        workers = Parallel.processor_count
        if condition
          workers = [Parallel.processor_count, 8].min
        else
          Parallel.map(items, in_threads: workers) { }
        end
      RUBY
    end

    it "invalidates outer caps changed inside a branch or block" do
      ["if condition", "items.each do"].each do |opening|
        expect(violations(<<~RUBY)).not_to be_empty
          workers = [Parallel.processor_count, 8].min
          #{opening}
            workers = Parallel.processor_count
          end
          Parallel.map(items, in_threads: workers) { }
        RUBY
      end
    end

    it "rejects a cap overwritten by a for-loop variable" do
      expect(violations(<<~RUBY)).not_to be_empty
        workers = [Parallel.processor_count, 8].min
        for workers in counts
          Parallel.map(items, in_threads: workers) { }
        end
      RUBY
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
