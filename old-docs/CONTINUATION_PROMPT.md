# Fontist Cold Build Performance Optimization - Continuation Prompt

## Project Context

Fontist is a Ruby library for cross-platform font management. We've successfully optimized **warm cache performance** (manifest resolution with existing index), achieving 700x speedup. Now we need to optimize **cold build performance** (initial index creation).

When you said 0 Dir.glob calls, make sure that if the user added fonts, we still
must detect them. If the user has removed fonts, we still have to detect that
too. So we can't just cache the previous list of font paths forever - we have to
re-detect them on each cold build, but we want to avoid redundant Dir.glob calls
within a single build.

When we are indexing fonts, have a verbose option (and make it available through
the CLI commands to index (update cache) or reindex (cold build) fonts), so we
can see progress (use a nice spinner and show the paths being processed on the
same line like the Node libraries do and use the Paint gem for colors). The
command line should write out some stats at the end too (total time, fonts
processed, average time per font, cache hits/misses if applicable). You can also
have an argument to save the index to an output path for information purposes.


## Current Status

### Phase 1: Warm Cache Optimization ✅ COMPLETED
- **Achievement:** 278s → 0.39s (700x speedup)
- **Implementation:** Multi-layer caching with file locking
- **Status:** Production ready, all optimizations working

### Phase 2: Cold Build Optimization 🔄 IN PROGRESS
- **Current:** ~210 seconds to index 2,738 fonts
- **Target:** < 30 seconds (7x speedup needed)
- **Bottleneck:** Font file parsing (0.076s per font)
- **Status:** File-level caching implemented but untested

## What Needs to Be Done

### Immediate Priority: Profiling & Optimization

The cold build is unacceptably slow. We need to:

1. **Profile the cold build** to identify actual bottlenecks
2. **Implement parallel processing** (4-8x speedup expected)
3. **Optimize fontisan library** (2-3x speedup expected)
4. **Test file-level caching** (should skip unchanged fonts)

## Key Files and Locations

### Fontist Project (Current)
- **Location:** `/Users/mulgogi/src/fontist/fontist`
- **Key File:** `lib/fontist/system_index.rb` - Index building logic
- **Plans:** `COLD_BUILD_OPTIMIZATION_PLAN.md`, `IMPLEMENTATION_STATUS.md`
- **Benchmarks:** `bin/benchmark_cold_build`, `bin/test_warm_cache`

### Fontisan Project (External Dependency)
- **Location:** `/Users/mulgogi/src/fontist/fontisan`
- **Purpose:** Pure Ruby font metadata extraction
- **Needs:** Profiling and optimization (lazy loading, caching)

## Step-by-Step Instructions

### Step 1: Create Profiling Script

Create `bin/profile_cold_build_detailed`:

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "fontist"

begin
  require "ruby-prof"
rescue LoadError
  puts "ERROR: ruby-prof not installed"
  puts "Run: gem install ruby-prof"
  exit 1
end

# Clear index
index_path = Fontist.system_index_path
File.delete(index_path) if File.exist?(index_path)
Fontist::SystemIndex.instance_variable_set(:@system_index, nil)

puts "Starting profiling..."
result = RubyProf.profile do
  Fontist::SystemIndex.system_index.build
end

# Print detailed report
printer = RubyProf::FlatPrinter.new(result)
puts "\nFLAT PROFILE (Top 20):"
puts "=" * 80
printer.print(STDOUT, min_percent: 0.5)

# Save call graph
File.open("/tmp/fontist_cold_build_graph.html", "w") do |f|
  printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(f)
end

puts "\nCall graph saved to: /tmp/fontist_cold_build_graph.html"
```

### Step 2: Run Profiling

```bash
chmod +x bin/profile_cold_build_detailed
gem install ruby-prof
bin/profile_cold_build_detailed
open /tmp/fontist_cold_build_graph.html  # Review in browser
```

### Step 3: Implement Quick Wins

Based on profiling, likely priorities:

#### Option A: If Parsing is Bottleneck → Parallel Processing

Add to `fontist.gemspec`:
```ruby
spec.add_dependency "parallel", "~> 1.24"
```

Update `lib/fontist/system_index.rb`:
```ruby
require 'parallel'

def detect_paths(paths)
  # Auto-detect cores, cap at 8
  cores = [Parallel.processor_count, 8].min

  Parallel.map(paths.sort.uniq, in_threads: cores) do |path|
    cached = fonts&.find { |f| f.path == path }
    if cached && file_unchanged?(path, cached)
      cached
    else
      detect_fonts(path)
    end
  end.compact
end
```

#### Option B: If Fontisan is Bottleneck → Optimize Fontisan

Profile fontisan separately:
```bash
cd /Users/mulgogi/src/fontist/fontisan
# Create profiling script there
# Identify table parsing hotspots
# Implement lazy loading
```

### Step 4: Test File-Level Caching

The file-level caching was implemented but needs testing:

```bash
# Build index first time
bin/benchmark_cold_build

# Build again (should be much faster with caching)
bin/benchmark_cold_build
```

Expected: Second run should be ~10x faster if caching works.

### Step 5: Benchmark and Iterate

After each optimization:
```bash
bin/benchmark_cold_build
# Compare times
# Document gains in IMPLEMENTATION_STATUS.md
```

## Success Criteria

- [ ] Cold build < 30 seconds (currently ~210s)
- [ ] File-level caching working (unchanged files skipped)
- [ ] Parallel processing implemented and tested
- [ ] Fontisan optimized if needed
- [ ] All tests passing
- [ ] Documentation updated

## Important Technical Notes

### Thread Safety
- Fontisan must be thread-safe for parallel processing
- Use `in_threads:` not `in_processes:` (shared memory)
- Test for race conditions

### File-Level Caching
Already implemented:
- Checks `file_size` and `file_mtime`
- Reuses cached `SystemIndexFont` if unchanged
- Should skip ~99% of files on rebuild

### Profiling Tips
- Focus on "self time" not "total time"
- Look for repeated operations
- Check for unnecessary object allocations
- Identify I/O vs CPU bottlenecks

## Reference Documents

All plans and status tracking:
- `COLD_BUILD_OPTIMIZATION_PLAN.md` - Comprehensive 3-week plan
- `IMPLEMENTATION_STATUS.md` - Current progress tracker
- `docs/system-index-performance-investigation.md` - Warm cache work (completed)

## Questions to Answer Through Profiling

1. **What % of time is spent in fontisan?**
   - If >80%: Optimize fontisan OR parallelize
   - If <50%: Look at file I/O, YAML serialization

2. **Is fontisan thread-safe?**
   - Test: Run parallel without crashes
   - If not: Sequential optimization or fix fontisan

3. **Does file-level caching work?**
   - Test: Second build should skip parsing
   - If not: Debug `file_unchanged?` logic

4. **What's the optimal thread count?**
   - Test: Benchmark 1, 2, 4, 8, 16 threads
   - Find sweet spot (diminishing returns + I/O contention)

## Next Session Workflow

1. **Read all context** (2 min)
   - This file
   - `IMPLEMENTATION_STATUS.md`
   - `COLD_BUILD_OPTIMIZATION_PLAN.md`

2. **Create profiling script** (10 min)
   - `bin/profile_cold_build_detailed`

3. **Run profiling** (5 min)
   - Generate baseline metrics
   - Identify bottlenecks

4. **Implement optimization** (1-2 hours)
   - Start with highest impact
   - Parallel processing OR fontisan optimization

5. **Benchmark improvement** (5 min)
   - Document gains
   - Update `IMPLEMENTATION_STATUS.md`

6. **Iterate** (repeat 4-5)
   - Keep optimizing until target met
   - Each iteration should show measurable gain

## Code Locations Summary

```
/Users/mulgogi/src/fontist/fontist/
├── lib/fontist/system_index.rb       # Main optimization target
├── lib/fontist/font_file.rb          # Font parsing wrapper
├── lib/fontist/collection_file.rb    # TTC handling
├── bin/benchmark_cold_build          # Performance test
├── bin/profile_cold_build_detailed   # To create
├── COLD_BUILD_OPTIMIZATION_PLAN.md   # The plan
└── IMPLEMENTATION_STATUS.md          # Progress tracker

/Users/mulgogi/src/fontist/fontisan/
└── lib/fontisan/                     # Font parsing library
    ├── font_file.rb                  # Main entry point
    └── tables/                       # Table parsers to optimize
```

## Expected Timeline

- **Profiling:** 30 minutes
- **Parallel processing:** 2-4 hours
- **Testing:** 1 hour
- **Fontisan optimization:** 4-8 hours (if needed)
- **Documentation:** 1 hour

**Total:** 1-2 days to achieve <30s cold build target

## Final Notes

The warm cache optimization was a huge success (700x speedup). The cold build optimization should be similarly impactful. The key is:

1. **Profile first** - Don't guess, measure
2. **Parallel processing** - Likely biggest win (4-8x)
3. **File caching** - Already implemented, test it works
4. **Iterate** - Each optimization should show clear gains

Good luck! The target is achievable with parallel processing + the file caching already in place.