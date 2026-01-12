# Google Protobuf Investigation - Quick Summary

**Date:** 2025-11-17
**Status:** ✅ Investigation Complete

## Key Finding

**google-protobuf gem CANNOT parse text format METADATA.pb files**

## Why?

The google-protobuf Ruby gem only supports:
- ✅ Binary wire format (`.bin` files)
- ✅ Programmatic schema definition
- ❌ Text format parsing (`.pb`, `.textproto` files)

The `Google::Protobuf::TextFormat` module **does not exist** in the Ruby implementation.

## Current Implementation

**File:** [`lib/fontist/import/google/metadata_parser.rb`](../lib/fontist/import/google/metadata_parser.rb:1)

**Method:** Regex-based text parsing

**Performance:** 37 microseconds per parse (tested with 1000 iterations)

**Status:** ✅ Production-tested with 1,976+ Google Fonts formulas

## Recommendation

### ✅ KEEP CURRENT IMPLEMENTATION

**Reasons:**
1. google-protobuf provides NO benefit for text format files
2. Regex parser is fast, simple, and production-proven
3. Pure Ruby implementation (no external dependencies)
4. Cross-platform compatible
5. Already handles all Google Fonts METADATA.pb formats

### Optional: Update TODO Comment

The TODO comment in [`metadata_parser.rb:3-6`](../lib/fontist/import/google/metadata_parser.rb:3) suggests this is temporary, but it's actually the **correct solution**.

**Suggested replacement:**
```ruby
# MetadataParser uses regex-based parsing for METADATA.pb text format files.
# This is the appropriate approach because:
# 1. google-protobuf gem only supports binary wire format, not text format
# 2. Text format parsing requires protoc compiler (external dependency)
# 3. Regex parsing is fast (37μs), simple, and production-tested
# 4. Maintains pure Ruby implementation without external processes
```

## Alternatives Considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **google-protobuf** | "Official" library | ❌ Can't parse text format | ❌ Not viable |
| **protoc + google-protobuf** | Schema validation | ❌ External process, slow, complex | ❌ Not viable |
| **Current regex parser** | Fast, simple, pure Ruby | Manual parsing | ✅ **Recommended** |

## Action Items

- [x] Verify google-protobuf capabilities
- [x] Test current MetadataParser performance
- [x] Document findings
- [ ] Optionally update TODO comment (low priority)
- [ ] Continue using current implementation

## Full Report

See: [`docs/google-protobuf-investigation.md`](./google-protobuf-investigation.md:1)