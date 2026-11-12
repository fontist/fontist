require "spec_helper"

# Runtime contract (fontist#548): no fork, no Marshal, and every Parallel
# pool is a thread pool capped by a local variable assigned from
# `[..., N].min`. The guard covers every file under lib/fontist.
RSpec.describe "Runtime contract" do
  lib_files = Dir.glob(File.join(Fontist.root_path, "lib", "fontist", "**",
                                 "*.rb"))

  # Source with full-line comments removed.
  def self.code_of(file)
    File.readlines(file).reject { |l| l.strip.start_with?("#") }.join
  end

  # Argument text of each Parallel.<method>(...) call, via paren matching.
  def self.parallel_calls(source)
    source.to_enum(:scan, /Parallel\.(?!processor_count\b)\w+\(/).map do
      start = Regexp.last_match.end(0)
      depth = 1
      idx = start
      while idx < source.length && depth.positive?
        depth += 1 if source[idx] == "("
        depth -= 1 if source[idx] == ")"
        idx += 1
      end
      source[start...idx]
    end
  end

  it "finds lib files to scan" do
    expect(lib_files).not_to be_empty
  end

  lib_files.each do |file|
    relative = file.sub("#{Fontist.root_path}/", "")

    describe relative do
      let(:source) { self.class.superclass.code_of(file) }

      it "uses no Marshal, fork, or in_processes" do
        expect(source).not_to match(/\bMarshal\b/)
        expect(source).not_to match(/\b(Process\.)?fork\b/)
        expect(source).not_to match(/\bin_processes\b/)
      end

      it "caps every Parallel pool with a local variable" do
        self.class.superclass.parallel_calls(source).each do |args|
          match = args.match(/\bin_threads:\s*(\w+)\s*(?:[,)]|\z)/)
          expect(match).not_to be_nil,
                               "Parallel call without in_threads: #{args}"

          var = match[1]
          expect(source).to match(
            /\b#{Regexp.escape(var)}\s*=\s*\[[^\]\n]*,\s*\d+\s*\]\.min\b/,
          ), "in_threads: #{var} is not capped (use [..., N].min)"
        end
      end
    end
  end
end
