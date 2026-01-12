# Aggressive Cold Build Optimization Plan
# Target: < 30 seconds (currently ~180s - need 6x speedup)

**Deadline:** ASAP - Compress all phases
**Current:** 180 seconds
**Target:** < 30 seconds
**Required:** 6x speedup minimum

## Strategy: Multi-Pronged Attack

### Phase 1: Process-Based Parallelism (CRITICAL - 4-6x speedup)
**Timeline:** 4-6 hours
**Expected Gain:** 180s → 30-45s

Ruby's GIL prevents thread parallelism, but **process-based parallelism bypasses GIL**.

#### Implementation
1. **Use `in_processes` instead of `in_threads`**
   - Modify `detect_paths` in `lib/fontist/system_index.rb`
   - Use `Parallel.map(paths, in_processes: cores)`
   - Each process parses fonts independently

2. **Optimize inter-process communication**
   - Serialize only essential data
   - Use Marshal for Ruby objects
   - Minimize data transfer overhead

3. **Smart process pool management**
   - Auto-detect cores: `Parallel.processor_count`
   - Cap at 8-12 processes (sweet spot for I/O)
   - Handle process failures gracefully

4. **Progress reporting across processes**
   - Use shared memory or file-based progress tracking
   - Aggregate stats from all processes
   - Display unified progress bar

#### Code Changes
```ruby
# lib/fontist/system_index.rb

def detect_paths_parallel(paths, verbose: false, stats: nil)
  require 'parallel'

  num_cores = [Parallel.processor_count, 8].min

  # Process-based parallelism (bypasses GIL!)
  results = Parallel.map(paths, in_processes: num_cores) do |path|
    # Each process parses independently
    cached = check_cache(path)
    cached || parse_font(path)
  end

  results.flatten.compact
end
```

#### Testing
- Benchmark on 1, 2, 4, 8 processes
- Measure process spawn overhead
- Verify no data corruption
- Test on all platforms (macOS, Linux, Windows)

### Phase 2: Fontisan Optimization (SECONDARY - 2-3x speedup)
**Timeline:** 6-8 hours
**Expected Gain:** Combined with Phase 1 → < 20s

Target fontisan library at `/Users/mulgogi/src/fontist/fontisan`

#### Profile First
```bash
cd /Users/mulgogi/src/fontist/fontisan
# Create profiling benchmark
ruby -e '
require "ruby-prof"
require "fontisan"

result = RubyProf.profile do
  1000.times { Fontisan::FontFile.new(FONT_PATH) }
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
'
```

#### Optimization Targets
1. **Lazy table loading**
   - Only parse name table and head table
   - Skip GSUB, GPOS, kern tables (not needed for indexing)
   - Add `tables: [:name, :head]` option

2. **String optimization**
   - Use frozen strings everywhere
   - Reduce string allocations in table parsing
   - Cache frequently accessed strings

3. **Memory optimization**
   - Use string slicing instead of duplication
   - Release unused data early
   - Avoid unnecessary object creation

4. **I/O optimization**
   - Read only required bytes
   - Use buffered reading for large files
   - Memory-map very large files (>10MB)

#### Expected Results
Current: 0.087s per font
Target: 0.030s per font (3x faster)

### Phase 3: Smart Caching Enhancement (TERTIARY - marginal gain)
**Timeline:** 2 hours
**Expected Gain:** Faster lukewarm builds

Already implemented but can enhance:

1. **Content-based hashing**
   - Add SHA256 hash to cache key
   - Detect file renames/moves
   - More robust than mtime

2. **Persistent cache across rebuilds**
   - Store parsed metadata in separate cache file
   - Never re-parse unchanged fonts
   - Invalidate only on file change

### Phase 4: Binary Index Format (FUTURE)
**Timeline:** 4-6 hours
**Expected Gain:** 5-10x I/O speedup

Not critical for <30s goal but good for future:

1. **MessagePack instead of YAML**
   - 5-10x faster serialization
   - Smaller file size
   - Binary format

2. **SQLite backend**
   - Instant queries
   - Concurrent read access
   - Incremental updates

## Implementation Order (Aggressive Schedule)

### Day 1 (8 hours)
- [x] Morning (4h): Implement process-based parallelism
  - Modify `detect_paths` for `in_processes`
  - Handle serialization
  - Test on sample set

- [x] Afternoon (4h): Test and optimize
  - Benchmark on full font set
  - Tune process count
  - Fix any issues
  - **Target: < 45 seconds**

### Day 2 (8 hours)
- [x] Morning (4h): Profile and optimize fontisan
  - Profile current hotspots
  - Implement lazy loading
  - Optimize string handling

- [x] Afternoon (4h): Test combined optimizations
  - Run with both optimizations
  - Benchmark thoroughly
  - **Target: < 25 seconds**

### Day 3 (4 hours) - Polish
- [x] Morning (2h): Platform testing
  - Test on macOS, Linux, Windows
  - Fix platform-specific issues

- [x] Afternoon (2h): Documentation
  - Update README
  - Document performance gains
  - Release notes

## Success Metrics

| Phase | Target | Measurement |
|-------|--------|-------------|
| Baseline | 180s | Current state |
| After Phase 1 (processes) | 30-45s | 4-6x speedup |
| After Phase 2 (fontisan) | 15-25s | 7-12x speedup |
| **Final Target** | **< 30s** | **6x+ speedup** |

## Risk Mitigation

### Risk: Process overhead too high
**Mitigation:**
- Start with fewer processes (4)
- Benchmark incrementally
- Fall back to threads if needed

### Risk: Fontisan optimization insufficient
**Mitigation:**
- Focus on lazy loading first (biggest win)
- Consider C extension if needed
- Alternative: mmap for large files

### Risk: Platform compatibility
**Mitigation:**
- Test early on all platforms
- Graceful degradation
- Platform-specific tuning

## Code Changes Summary

### Modified Files
1. `lib/fontist/system_index.rb`
   - Change `in_threads` to `in_processes`
   - Optimize data serialization
   - Handle process communication

2. `/Users/mulgogi/src/fontist/fontisan/lib/fontisan/font_file.rb`
   - Add lazy table loading
   - Optimize string handling
   - Reduce allocations

3. `fontist.gemspec`
   - Already has `parallel` gem
   - No new dependencies needed

### New Files
None - all changes to existing files

## Testing Strategy

### Benchmark Script
```bash
#!/bin/bash
# bin/benchmark_processes

for cores in 1 2 4 8; do
  echo "Testing with $cores processes"
  FONTIST_PROCESSES=$cores bin/benchmark_cold_build
done
```

### Validation
- Cold build < 30s ✓
- Lukewarm build < 3s ✓
- No data corruption ✓
- All tests passing ✓
- Works on all platforms ✓

## Expected Final Results

```
Before:
- Cold build: 180s
- Lukewarm: 2.3s

After Phase 1 (processes):
- Cold build: 35-40s (5x speedup)
- Lukewarm: 2.3s (unchanged)

After Phase 2 (fontisan):
- Cold build: 20-25s (8x speedup)
- Lukewarm: 1.5s (1.5x speedup)

FINAL:
- Cold build: < 30s ✓ TARGET MET
- Lukewarm: < 2s
```

## Next Steps

1. Implement `in_processes` parallelism (PRIORITY 1)
2. Benchmark and verify < 45s
3. If needed, optimize fontisan (PRIORITY 2)
4. Final testing and documentation
5. Ship it!

## Notes

- Process-based parallelism is THE key to hitting <30s
- Ruby GIL was blocking us with threads
- Fontisan optimization is secondary but valuable
- File caching already works great (90x on lukewarm)
- Target is achievable with focused execution