# Fontist Cold Build Optimization Plan

## Current Performance Baseline

**Cold Build (Fresh Index):**
- Time: ~210 seconds (3.5 minutes)
- Fonts Parsed: 2,738
- Time per Font: 0.076 seconds
- Bottleneck: Font file parsing via fontisan

**Target Performance:**
- Cold Build: < 30 seconds (7x speedup required)
- Lukewarm Build: < 5 seconds (rebuild with few changes)
- Warm Build: < 1 second (already achieved)

## Root Cause Analysis

### Profiling Results Needed
1. **Ruby-prof analysis** of cold build
2. **Stackprof flamegraph** to identify hotspots
3. **Memory profiling** to find allocation bottlenecks

### Known Bottlenecks
1. **Fontisan parsing** - 0.076s × 2738 = 208s total
2. **File I/O** - Reading thousands of font files
3. **YAML serialization** - Writing large index file

## Optimization Strategy

### Phase 1: Parallel Processing (Highest Impact)
**Expected Speedup:** 4-8x on multi-core systems

#### 1.1 Parallel Font Parsing
```ruby
require 'parallel'

def detect_paths_parallel(paths)
  Parallel.map(paths, in_threads: 8) do |path|
    detect_fonts(path)
  end.flatten.compact
end
```

**Implementation:**
- Add `parallel` gem dependency
- Detect CPU cores: `Parallel.processor_count`
- Use thread pool (not processes - shared memory)
- Thread-safe font collection building

**Considerations:**
- fontisan must be thread-safe
- File I/O contention (limit threads)
- Progress reporting in parallel mode

#### 1.2 Batch YAML Writing
Currently: Write entire index at once
Optimization: Build in chunks, write incrementally

### Phase 2: Fontisan Optimization
**Expected Speedup:** 2-3x

#### 2.1 Profile Fontisan Hotspots
Located at: `/Users/mulgogi/src/fontist/fontisan`

**Areas to investigate:**
1. Name table parsing efficiency
2. Unnecessary table reads
3. String allocations
4. Table caching

#### 2.2 Lazy Loading
Only parse tables actually needed:
- Name table (family, subfamily names)
- Head table (version)
- Skip: GSUB, GPOS, kern (not needed for indexing)

#### 2.3 Memory-Mapped Files
Use `mmap` for large font files instead of `File.read`

### Phase 3: Smart Caching (Already Partially Implemented)
**Expected Speedup:** 100x for unchanged files

#### 3.1 File-Level Caching (Implemented)
✅ Check mtime + size before parsing
✅ Reuse cached metadata for unchanged files

#### 3.2 Content-Based Hashing
- Add SHA256 hash to cache key
- Detect file renames/moves
- Handle timestamp changes

### Phase 4: Progressive Indexing
**Expected Speed

up:** Perceived instant for common use

#### 4.1 Lazy Index Building
- Build index on-demand per directory
- User queries trigger indexing
- Background indexer for full scan

#### 4.2 Incremental Updates
- Track which directories scanned
- Only scan new/changed directories
- Merge partial indexes

### Phase 5: Binary Index Format
**Expected Speedup:** 5-10x for I/O

#### 5.1 MessagePack Instead of YAML
- Faster serialization/deserialization
- Smaller file size
- Binary format

#### 5.2 SQLite Index
- Index in SQLite database
- SQL queries for font lookup
- Concurrent read access
- Atomic updates

## Detailed Implementation Plan

### Week 1: Profiling and Parallel Processing

#### Day 1: Profiling Setup
- [ ] Add ruby-prof gem
- [ ] Create profiling benchmark script
- [ ] Generate flamegraph
- [ ] Identify top 10 hotspots
- [ ] Document findings

#### Day 2-3: Parallel Font Parsing
- [ ] Add `parallel` gem to gemspec
- [ ] Implement thread pool
 in `detect_paths`
- [ ] Ensure thread-safety in fontisan
- [ ] Add progress reporting
- [ ] Benchmark parallel vs sequential
- [ ] Test on 1, 2, 4, 8 cores

#### Day 4: Testing and Refinement
- [ ] Run full test suite
- [ ] Fix any race conditions
- [ ] Optimize thread count
- [ ] Document performance gains

### Week 2: Fontisan Optimization

#### Day 1: Fontisan Profiling
- [ ] Profile fontisan separately
- [ ] Identify table parsing hotspots
- [ ] Measure table read times
- [ ] Find allocation hotspots

#### Day 2-3: Fontisan Lazy Loading
- [ ] Implement lazy table loading
- [ ] Skip unnecessary tables
- [ ] Cache frequently accessed tables
- [ ] Add benchmarks

#### Day 4: Memory Optimizations
- [ ] Reduce string allocations
- [ ] Use frozen strings
- [ ] Pool common objects
- [ ] Benchmark memory usage

### Week 3: Advanced Optimizations

#### Day 1-2: Binary Index Format
- [ ] Design MessagePack schema
- [ ] Implement serializer/deserializer
- [ ] Migration path from YAML
- [ ] Backward compatibility

#### Day 3: Progressive Indexing
- [ ] Design incremental index architecture
- [ ] Implement directory-level tracking
- [ ] Merge strategy for partial indexes

#### Day 4: Final Testing
- [ ] Full integration testing
- [ ] Performance benchmarking
- [ ] Documentation updates
- [ ] Release preparation

## Success Metrics

### Performance Targets
- **Cold Build:** < 30 seconds (currently ~210s)
- **Lukewarm Build:** < 5 seconds (few changes)
- **Warm Build:** < 1 second (no changes) ✅ Achieved
- **Manifest Resolution:** < 1 second ✅ Achieved

### Quality Targets
- **Test Coverage:** > 95%
- **Test Pass Rate:** 100%
- **Memory Usage:** < 500MB during indexing
- **Thread Safety:** No race conditions
- **Backward Compatibility:** Support YAML indexes

## Risk Mitigation

### Risks
1. **Thread safety in fontisan** - May require significant refactoring
2. **Parallel overhead** - Could be slower on single-core systems
3. **Binary format migration** - Users with old indexes
4. **Complexity increase** - Harder to debug

### Mitigation Strategies
1. Comprehensive testing on all platforms
2. Auto-detect cores, fallback to sequential
3. Automatic migration on first use
4. Clear documentation and logging

## Files to Modify

### Fontist
- `lib/fontist/system_index.rb` - Parallel processing
- `lib/fontist/font_file.rb` - Lazy loading integration
- `lib/fontist/collection_file.rb` - Parallel TTC handling
- `fontist.gemspec` - Add `parallel` gem

### Fontisan (External Project)
- `lib/fontisan/font_file.rb` - Lazy table loading
- `lib/fontisan/tables/name.rb` - Optimization
- `lib/fontisan/tables/head.rb` - Optimization
- Add benchmarking suite

## Documentation Updates

### To Update
- `README.adoc` - Performance section
- `docs/guide/index.md` - Best practices
- `CHANGELOG.md` - Performance improvements

### To Move to old-docs/
- `docs/system-index-performance-investigation.md` (after extraction to README)

## Dependencies

### New Gems Required
- `parallel` (~> 1.24) - Parallel processing
- `msgpack` (~> 1.7) - Binary serialization (optional)
- `ruby-prof` (~> 1.7) - Profiling (development only)
- `stackprof` (~> 0.2) - Stack profiling (development only)

### External Projects
- fontisan - Font metadata extraction library
- Requires coordination if major refactoring needed

## Timeline

### Immediate (This Week)
- Profile current implementation
- Implement parallel processing
- Benchmark and document gains

### Short Term (Next 2 Weeks)
- Optimize fontisan
- Implement file-level caching fully
- Binary index format prototype

### Long Term (Next Month)
- Progressive indexing
- SQLite backend option
- Production release

## Next Steps

1. **Create profiling scripts** - `bin/profile_cold_build`
2. **Run ruby-prof** - Identify actual bottlenecks
3. **Implement parallel processing** - Quick win
4. **Profile fontisan** - Coordinate optimization
5. **Release beta** - Get user feedback

## Status Tracking

See `IMPLEMENTATION_STATUS.md` for detailed progress tracking.