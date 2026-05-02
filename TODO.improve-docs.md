# Fontist Documentation Improvement Plan

**Goal:** Achieve 100% documentation coverage of README.adoc content in docs/

**Status:** ✅ Complete

---

## Phase 1: Platform-Specific Guides (Critical)

### 1.1 Create macOS Platform Guide
- [x] Create `/docs/guide/platforms/macos.md`
- [x] Document supplementary fonts framework
- [x] Document framework versioning (Font3-Font8)
- [x] Document platform tags (`macos-fontX`)
- [x] Document version compatibility checking
- [x] Include macOS version → framework table
- [x] Add link to Fontist blog post

### 1.2 Create Windows Platform Guide
- [x] Create `/docs/guide/platforms/windows.md`
- [x] Document Windows font management differences
- [x] Document Windows font locations
- [x] Document file locking considerations
- [x] Document path handling
- [x] Document registry integration
- [x] Document administrator privileges
- [x] Include platform compatibility table

---

## Phase 2: Installation Improvements

### 2.1 Update Installation Guide
- [x] Add detailed dependency table (json, brotli, seven-zip, libmspack, ffi-libarchive-binary)
- [x] Add Windows RubyInstaller DevKit steps (`ridk install`)
- [x] Add Git as prerequisite for update/repo commands
- [x] Add note about native extension compilation

---

## Phase 3: Formula Advanced Features

### 3.1 Update Formulas Guide
- [x] Add `override:` key documentation (already present)
- [x] Add Frutiger fonts example (already present)
- [x] Add HTTP authentication for private repos (already present)
- [x] Add authorization headers example (already present)
- [x] Add token scope requirements (already present)

### 3.2 Update create-formula CLI
- [x] Add `--name-prefix` option with example (already documented)

---

## Phase 4: How It Works Improvements

### 4.1 Update How It Works Guide
- [x] Add managed vs non-managed locations section (already present)
- [x] Add font discovery behavior explanation (already present)
- [x] Add import cache environment variables (already present)

---

## Phase 5: Maintainer Documentation (Clearly Marked)

### 5.1 Create Maintainer Import Guide
- [x] Create `/docs/guide/maintainer/index.md`
- [x] Create `/docs/guide/maintainer/import.md`
- [x] Mark as "Maintainer Only" clearly
- [x] Document `fontist import google` command
- [x] Document Google Fonts API integration
- [x] Document import source architecture
- [x] Document versioned filenames
- [x] Document import cache Ruby API

### 5.2 Update CLI Import Reference
- [x] Add `fontist import google` to `/docs/cli/import.md` (already present)
- [x] Add maintainer-only notice

---

## Phase 6: Navigation Updates

### 6.1 Update VitePress Config
- [x] Add Platforms section to Guide sidebar
- [x] Add Maintainer section to Guide sidebar (collapsed)
- [x] Update navigation as needed

---

## Phase 7: Verification

### 7.1 Build and Test
- [x] Run `npm run build` to verify no errors
- [x] Run lychee link checker (manual verification with curl - lychee crashed)
- [x] Verify all new pages are accessible
- [x] Cross-check against README.adoc

---

## Progress Tracking

| Phase | Status | Items Done | Items Total |
|-------|--------|------------|-------------|
| 1. Platform Guides | ✅ Complete | 14 | 14 |
| 2. Installation | ✅ Complete | 4 | 4 |
| 3. Formula Features | ✅ Complete | 7 | 7 |
| 4. How It Works | ✅ Complete | 3 | 3 |
| 5. Maintainer Docs | ✅ Complete | 10 | 10 |
| 6. Navigation | ✅ Complete | 3 | 3 |
| 7. Verification | ✅ Complete | 4 | 4 |

**Total Progress: 45/45 items (100%)**
