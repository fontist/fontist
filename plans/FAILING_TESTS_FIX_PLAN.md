# Failing Tests Fix Plan

**Date:** 2025-01-08
**Workflow Run:** #20814928331

## Executive Summary

The CI workflow failed with issues across multiple platforms. After analysis, there are **3 distinct issues** to fix:

| Issue | Platforms Affected | Tests Failed | Priority |
|-------|-------------------|--------------|----------|
| AU Passata URL broken | Ubuntu 3.1, macOS 3.1 | 1 | High |
| Windows CLI path tests | Windows 3.1, 3.4 | 5 | High |
| Windows Git network test | Windows 3.1, 3.4 | 1 | Medium |

## Workflow Final Results

| Platform | Ruby Version | Status | Failures |
|----------|--------------|--------|----------|
| **Ubuntu** | 3.1 | ❌ FAIL | 1 (AU Passata URL) |
| **Ubuntu** | 3.4 | ✅ PASS | 0 |
| **macOS** | 3.1 | ❌ FAIL | 1 (AU Passata URL) |
| **macOS** | 3.4 | ✅ PASS | 0 |
| **Windows** | 3.1 | ❌ FAIL | 66 (5 CLI + 1 Git + others) |
| **Windows** | 3.4 | ❌ FAIL | Same issues |
| **Arch Linux** | - | ✅ PASS | 0 |

---

## Issue 1: AU Passata URL Returns HTTP 418

### Description
The Aarhus University server is blocking download requests, returning HTTP 418 "I'm A Teapot":

```
Fontist::Errors::InvalidResourceError:
  Invalid URL: https://medarbejdere.au.dk/fileadmin/www.designmanual.au.dk/hent_filer/hent_skrifttyper/fonte.zip
  Error: #<Down::ClientError: 418 I'm A Teapot>.
```

### Affected Test
- File: `spec/fontist/font_spec.rb:658`
- Test: `Fontist::Font.install two formulas with the same font diff styles installs both`

### Root Cause
The formula `spec/examples/formulas/au.yml` uses a URL to Aarhus University that is now blocked.

### Solution: Replace with GitHub-hosted font

**Step 1:** Create a replacement test formula with a working URL

Replace the test with one using fonts from a reliable source (GitHub-hosted).

**Option A (Recommended):** Modify the test to use two existing formulas that have working URLs:

```ruby
context "diff styles" do
  let(:font) { "Source Code Pro" }
  # Use source.yml and source_code_pro.yml which both exist
  before { example_formula("source.yml") }
  before { example_formula("source_code_pro.yml") }
  before { set_size_limit(1000) }

  it "installs both" do
    expect(Fontist::FontInstaller).to receive(:new).twice
      .and_call_original
    command
  end
end
```

**Option B:** Create a new test formula with GitHub-hosted fonts (e.g., Fira Code which uses GitHub releases).

**Files to modify:**
1. `spec/fontist/font_spec.rb:648-660` - Replace AU formulas with working alternatives
2. Optionally remove `spec/examples/formulas/au.yml` and `au_passata_oblique.yml` if no longer needed

---

## Issue 2: Windows CLI Path Tests (5 failures)

### Description
CLI tests expect `Fontist.ui.say` to be called with paths containing font filenames, but the calls never happen on Windows.

### Affected Tests
1. `spec/fontist/cli_spec.rb:303` - `formula from root dir returns success status and prints fonts paths`
2. `spec/fontist/cli_spec.rb:320` - `formula from subdir returns success status and prints fonts paths`
3. `spec/fontist/cli_spec.rb:345` - `suggested formula is chosen installs the formula`
4. `spec/fontist/cli_spec.rb:692` - `manifest_locations contains one font with regular style`
5. `spec/fontist/cli_spec.rb:706` - `manifest_locations contains one font with bold style`

### Root Cause Analysis

The tests are structured like:
```ruby
context "formula from root dir" do
  let(:formula) { "andale" }
  before do
    allow(Fontist.ui).to receive(:ask).and_return("yes").once
    example_formula("andale.yml")
  end

  it "returns success status and prints fonts paths" do
    expect(Fontist.ui).to receive(:say).with(include("AndaleMo.TTF"))
    expect(command).to be 0
  end
end
```

**Hypothesis:** On Windows, the font installation is actually happening but the `.say` method isn't being called with the expected output. This could be due to:

1. **Path separator differences** - Windows uses `\` vs Unix `/`
2. **Case sensitivity** - Windows is case-insensitive, tests might be looking for wrong case
3. **Include context issue** - The `include_context "fresh home"` setup might not work correctly on Windows
4. **Index not building** - The font index might not be finding the installed fonts

### Investigation Steps

1. Add debug output to see what `Fontist.ui.say` is actually called with on Windows
2. Check if fonts are being installed to the expected paths
3. Verify index building works on Windows

### Proposed Solution

**Step 1:** Add Windows-specific path handling in the test matchers

```ruby
it "returns success status and prints fonts paths" do
  # Use case-insensitive match that works on both platforms
  expect(Fontist.ui).to receive(:say).with(match(/AndaleMo\.TTF/i))
  expect(command).to be 0
end
```

**Step 2:** Ensure the `fresh home` context properly initializes on Windows

Check that `fresh_fontist_home` in `fontist_helper.rb` correctly handles Windows paths.

**Step 3:** Add explicit cache and index resets before these tests

```ruby
before(:each) do
  Fontist::Indexes::FontistIndex.reset_cache
  Fontist::Indexes::UserIndex.reset_cache
  Fontist::Indexes::SystemIndex.reset_cache
end
```

---

## Issue 3: Windows Git Network Test Failure

### Description
The test `Fontist::Update private repo is set up before the main one fetches the main repo` fails with:

```
Git::FailedError:
  fatal: unable to access 'https://github.com/fontist/formulas.git/':
  getaddrinfo() thread failed to start
```

### Affected Test
- File: `spec/fontist/update_spec.rb:95-109`

### Root Cause
The test tries to stub `Fontist.formulas_repo_url` but the actual git fetch still tries to contact the real GitHub URL. This is likely a timing issue where the stub isn't applied before the network call.

### Solution

**Option A (Recommended):** Ensure the stub is applied correctly and completely mock the remote

```ruby
context "private repo is set up before the main one" do
  it "fetches the main repo" do
    fresh_fontist_home do
      remote_main_repo do |main_repo_url|
        # Stub BEFORE any operations
        allow(Fontist).to receive(:formulas_repo_url)
          .and_return(main_repo_url)

        # Also stub the fetch to avoid network calls
        allow_any_instance_of(Git::Base).to receive(:fetch)
          .and_return(true)

        formula_repo_with("andale.yml") do |private_repo_url|
          Fontist::Repo.setup("example", private_repo_url)

          command.call
        end
      end
    end
  end
end
```

**Option B:** Skip this test on Windows CI

```ruby
context "private repo is set up before the main one", skip: Fontist::Utils::System.user_os == :windows && ENV["CI"] do
  it "fetches the main repo" do
    # ... test code
  end
end
```

**Option C:** Add retry logic for Windows network issues

---

## Implementation Order

1. **Issue 1 (AU Passata)** - Simple fix, replace formula reference
2. **Issue 3 (Git Network)** - Add proper mocking to avoid network calls
3. **Issue 2 (Windows CLI)** - Most complex, requires investigation

## Files to Modify

### For Issue 1:
- `spec/fontist/font_spec.rb` (lines 648-660)

### For Issue 2:
- `spec/fontist/cli_spec.rb` (lines 303, 320, 345, 692, 706)
- Possibly `spec/support/fontist_helper.rb` for Windows path handling

### For Issue 3:
- `spec/fontist/update_spec.rb` (lines 95-109)

## Testing the Fixes

After implementing fixes:
1. Run tests locally on each platform if possible
2. Push to a feature branch
3. Monitor CI workflow for all platforms
4. Verify all 7 platform/Ruby combinations pass

## Success Criteria

- ✅ All 7 CI jobs pass (Ubuntu 3.1/3.4, macOS 3.1/3.4, Windows 3.1/3.4, Arch)
- ✅ No test skips (prefer real fixes over skipping)
- ✅ Tests remain meaningful and provide coverage