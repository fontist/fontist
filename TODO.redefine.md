# Method Redefinition Warning Fix - COMPLETED

## Issue
Fontist was redefining setter methods from lutaml-model, causing Ruby warnings:

```
fontist-2.0.4/lib/fontist/config.rb:120: warning: method redefined; discarding old fonts_path=
lutaml-model-0.7.7/lib/lutaml/model/serialize.rb:124: warning: previous definition of fonts_path= was here
```

## Important: What This Fix Addresses

**✅ FIXED:** The Fontist-specific warning (`fonts_path=` from `lib/fontist/config.rb`)

**NOT in scope for Fontist:** The remaining warnings are from **external gems** (lutaml-model, git, moxml, arr-pm):
- `lutaml-model-0.7.7/.../collection.rb:36: warning: method redefined; discarding old entries=`
- `lutaml-model-0.7.7/.../collection.rb:36: warning: method redefined; discarding old fonts=`
- `lutaml-model-0.7.7/.../collection.rb:36: warning: method redefined; discarding old formulas=`
- `lutaml-model-0.7.7/.../collection.rb:36: warning: method redefined; discarding old resources=`

These warnings originate from **lutaml-model gem's internal implementation** and must be fixed in the lutaml-model project itself, not in Fontist.

## Root Cause
The `Config` class:
1. Inherits from `Lutaml::Model::Serializable` which auto-generates `fonts_path=` setter
2. Manually defined `fonts_path=` (line 120-123) to add path expansion behavior
3. This caused the redefinition warning

## Solution
Removed the manual setter and moved path expansion logic into the `set` method:

```ruby
def set(key, value)
  attr = key.to_sym
  unless default_values.key?(attr)
    raise Errors::InvalidConfigAttributeError,
          "No such attribute '#{attr}' exists."
  end

  v = normalize_value(value)

  # Expand fonts_path to absolute path
  v = File.expand_path(v.to_s) if attr == :fonts_path

  @custom_values[attr] = v
  send("#{attr}=", v) if respond_to?("#{attr}=")

  persist
end
```

## Changes Made
- **File**: `lib/fontist/config.rb`
- **Removed**: Lines 120-123 (manual `fonts_path=` setter)
- **Modified**: Lines 73-89 (`set` method - added path expansion on line 83)

## Testing
All tests pass (9 examples, 0 failures):
- ✅ Path expansion to absolute path works
- ✅ Home directory (~) expansion works
- ✅ Relative path expansion works
- ✅ Config set/get/delete operations work
- ✅ CLI commands work correctly

## Verification
No `fonts_path=` redefinition warnings appear when loading Fontist:
```bash
ruby -w -e "require './lib/fontist'" 2>&1 | grep -i "fonts_path="
# (exit code 1 = no matches = success!)
```

## Status
✅ **COMPLETED** - Issue resolved, all tests passing
