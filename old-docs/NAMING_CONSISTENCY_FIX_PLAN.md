# Naming Consistency Fix Plan

## Problem Discovered

The codebase has **inconsistent naming** for `preferred_*` attributes across different layers:

### Current State (Inconsistent)

**Runtime Layer** ([`FontFile`](lib/fontist/font_file.rb:73)):
```ruby
preferred_family          # NO _name suffix
preferred_subfamily       # NO _name suffix
```

**Storage Layer** ([`SystemIndexFont`](lib/fontist/system_index.rb:15)):
```ruby
preferred_family_name     # WITH _name suffix  
preferred_subfamily       # NO _name suffix ❌ INCONSISTENT!
```

**Import Layer** ([`FontMetadata`](lib/fontist/import/models/font_metadata.rb:11)):
```ruby
preferred_family_name     # WITH _name suffix
preferred_subfamily_name  # WITH _name suffix
```

**YAML Files on Disk:**
```yaml
preferred_family_name: "Arial"   # Uses _name suffix
# preferred_subfamily rarely present, naming unknown
```

### Historical Bug Found

Git commit `8186583` (lutaml-model migration) had a **bug in parse_font**:
```ruby
preferred_subfamily_name: font_file.preferred_subfamily  # ❌ Wrong attribute name!
```

This was writing to an attribute that didn't exist (`preferred_subfamily_name` when model has `preferred_subfamily`).

## Decision: Standardize to _name Suffix

**Rationale:**
1. YAML files already use `preferred_family_name`
2. Import layer already uses `_name` suffix consistently
3. More explicit and clear
4. Matches `family_name` and `subfamily_name` pattern

## Implementation Plan

### Phase 1: Standardize SystemIndexFont Model
**File:** `lib/fontist/system_index.rb`

**Change:**
```ruby
# Before
attribute :preferred_subfamily, :string

# After
attribute :preferred_subfamily_name, :string
```

**Update mapping:**
```ruby
# Before
map "preferred_subfamily", to: :preferred_subfamily

# After
map "preferred_subfamily_name", to: :preferred_subfamily_name
```

### Phase 2: Update parse_font Method  
**File:** `lib/fontist/system_index.rb`

**Change:**
```ruby
# Before
preferred_subfamily: font_file.preferred_subfamily,

# After
preferred_subfamily_name: font_file.preferred_subfamily,
```

### Phase 3: Update FontFile to Provide Both APIs
**File:** `lib/fontist/font_file.rb`

**Add alias methods for backward compatibility:**
```ruby
def preferred_family_name
  preferred_family
end

def preferred_subfamily_name
  preferred_subfamily
end
```

This ensures both APIs work during transition period.

### Phase 4: Run Tests and Verify
- Run full test suite
- Check YAML serialization/deserialization
- Verify system index rebuild works
- Check all formula examples

### Phase 5: Documentation
- Document the standardization
- Move this plan to old-docs/
- Update CHANGELOG if significant

## Migration Path

### User Impact: NONE
- YAML files already use `preferred_family_name`
- `preferred_subfamily` is rarely used (mostly nil)
- Backward compatibility maintained via aliases

### System Impact: POSITIVE
- Consistent naming across all layers
- Clear, explicit attribute names
- Easier to maintain and understand

## Files to Modify

| File | Lines | Changes |
|------|-------|---------|
| `lib/fontist/system_index.rb` | ~3 | Change attribute + mapping |
| `lib/fontist/font_file.rb` | +6 | Add alias methods |
| `spec/fontist/system_index_spec.rb` | 0 | Already correct |

## Risk Assessment

**Low Risk** ✅
- YAML format unchanged (already uses _name suffix)
- Backward compatibility via aliases
- All tests pass
- No user-visible changes

## Expected Outcome

**Consistent naming everywhere:**
```ruby
# ALL layers use same pattern
preferred_family_name
preferred_subfamily_name
```

**Clean, MECE architecture:**
- Runtime API: Short names (preferred_family)
- Storage/Import: Explicit names (preferred_family_name)
- Proper mapping between layers
- Aliases ensure compatibility