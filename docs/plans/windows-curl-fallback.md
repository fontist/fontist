# Windows-only `curl.exe` fallback for downloads

## Goal

On Windows, when the Ruby SSL/socket layer raises the confirmed MinGW
`Errno::ENOTSOCK` defect, transparently fall back to `curl.exe` for the download
(and for GitHub release-asset URL resolution), leaving all non-Windows behavior
byte-for-byte unchanged.

## Root cause (confirmed via CI probe — NOT re-investigated)

In Windows Server 2025 `servercore:ltsc2025` containers with RubyInstaller/MinGW
Ruby (probed under 3.4.9), every outbound HTTPS through `Net::HTTP`/OpenSSL fails
with `Errno::ENOTSOCK` at `OpenSSL::SSL::SSLSocket#connect_nonblock`. Plain
`TCPSocket` connect works; native `curl.exe` works (302). The fault is the
OpenSSL <-> socket fd handoff on MinGW; a native process sidesteps it. The same
Ruby works on normal Windows — this only manifests in these containers.

This breaks two fontist code paths:

1. The download itself — `Down.download` in
   `Downloader#do_download_file_with_progress_bar`. Down flattens the OpenSSL
   error; it surfaces as a `Down::ConnectionError` whose message contains
   "not a socket" / "ENOTSOCK" (the errno is NOT preserved as a typed `#cause`).
2. GitHub release-asset URL **resolution** —
   `GitHubClient.authenticated_download_url` (Octokit -> Faraday -> Net::HTTP),
   which ENOTSOCKs *before* any download for `releases/download/...` URLs. Here
   the bare `Errno::ENOTSOCK` is preserved (typed, possibly wrapped via `#cause`).

So the detector must handle BOTH a typed `Errno::ENOTSOCK` (walked via the
`#cause` chain) AND a message-only `Down::ConnectionError`.

## Design (the tightened design requested by the prior plan review)

The single gate everywhere is `CurlDownloader.fallback?(error)` =
`available? && enotsock?(error)`. Both call sites (the download rescue and the
GitHub-URL rescue) use ONLY this gate. `GitHubClient` is NOT touched.

## Scope

IN scope:
- A Windows-only curl fallback, invoked **only** when `CurlDownloader.fallback?`
  (i.e. `Gem.win_platform?` AND the error is the ENOTSOCK signature).
- The download path and the GitHub-URL-resolution path, both inside
  `downloader.rb`.

OUT of scope (do NOT touch):
- `github_client.rb` — left completely untouched. The GitHub fallback lives in
  `downloader.rb#github_aware_url` by returning the raw `releases/download/...`
  URL (curl's `-L` follows the redirect).
- Any non-Windows behavior.
- The retry/backoff loop semantics for non-ENOTSOCK errors.
- Progress-bar accuracy for the curl path.
- Migrating away from Down/Octokit in general.
- Existing unrelated downloader/cache bugs.
- README/CHANGELOG.

## Files to touch (3: 1 new lib + 1 modified lib + 1 new spec; small touch to downloader_spec.rb)

### 1. NEW `lib/fontist/utils/curl_downloader.rb`

Owns ALL curl logic. Public surface:

- `CurlDownloader.fallback?(error)` => `available? && enotsock?(error)`. The ONE
  gate used by every call site.
- `CurlDownloader.available?` => `Gem.win_platform?`. On servercore `curl.exe`
  lives in System32 (always on PATH), so the platform check is sufficient — keep
  it simple, no separate presence probe.
- `CurlDownloader.enotsock?(error)` => walk the `#cause` chain returning true on
  any `Errno::ENOTSOCK`. If no typed errno is found, fall back to a documented
  string match ("not a socket" / "ENOTSOCK") on the message — this covers the
  case where Down flattens the errno into a message-only `Down::ConnectionError`.
  The WHY comment goes ONLY on the string branch. No redundant pre-loop
  `is_a?` check (the loop's first iteration already inspects the top error).
- Instance download method: build argv as an ARRAY (no shell interpolation of the
  URL), download to a `Tempfile`, return that Tempfile decorated with
  `original_filename` and `content_type`.

argv shape (array; URL after `--` so it can never be parsed as a flag):

```ruby
["curl.exe", "-fSL", "--retry", "3", "-A", user_agent, "-o", tmp.path, "--", url]
```

- `-f` fail on HTTP >= 400, `-S` show errors, `-L` follow redirects,
  `--retry 3`, `-A <user_agent>` (same browser UA Down would send), `-o <tmp>`.
- Run via `Open3.capture3(*argv)` (matches the existing `system.rb` idiom). On
  non-zero exit raise `Fontist::Errors::InvalidResourceError`.
- Returns a `Tempfile` (binmode) decorated so it satisfies the cache's duck-type
  contract. Document that contract in a comment: the cache needs
  `#original_filename`, `#content_type`, `#path`, `#close`.
- `content_type` may be nil. One-line comment stating the invariant:
  `cache.rb` only consults `content_type` when the URL has no extname, and font
  asset URLs always carry an extension — so nil is safe.
- `original_filename` = basename of the (post-`--`) URL path.

Sketch:

```ruby
require "open3"
require "tempfile"

module Fontist
  module Utils
    class CurlDownloader
      CURL = "curl.exe".freeze

      def self.fallback?(error)
        available? && enotsock?(error)
      end

      def self.available?
        Gem.win_platform?
      end

      def self.enotsock?(error)
        node = error
        while node
          return true if node.is_a?(Errno::ENOTSOCK)

          node = node.cause
        end

        # Down flattens the MinGW OpenSSL errno into a message-only
        # Down::ConnectionError (no typed #cause), so match the text as a
        # last resort.
        msg = error.message.to_s
        msg.include?("not a socket") || msg.include?("ENOTSOCK")
      end

      def initialize(url, user_agent:)
        @url = url
        @user_agent = user_agent
      end

      # Returns a Tempfile that satisfies the cache duck type:
      # #original_filename, #content_type, #path, #close.
      def download
        tempfile = Tempfile.new("fontist-curl", binmode: true)
        run(argv(tempfile.path))
        decorate(tempfile)
      end

      def argv(output_path)
        [CURL, "-fSL", "--retry", "3", "-A", @user_agent,
         "-o", output_path, "--", @url]
      end

      private

      def run(argv)
        _out, err, status = Open3.capture3(*argv)
        return if status.success?

        raise Fontist::Errors::InvalidResourceError,
              "curl failed for #{@url}: #{err.strip}"
      end

      def decorate(tempfile)
        filename = File.basename(URI(@url).path)
        tempfile.define_singleton_method(:original_filename) { filename }
        # content_type is nil: cache.rb only uses it when the URL has no
        # extname, and font asset URLs always carry one.
        tempfile.define_singleton_method(:content_type) { nil }
        tempfile
      end
    end
  end
end
```

### 2. `lib/fontist/utils/downloader.rb`

Two guarded edits, both routing through the SAME cache/SHA path; no SHA logic
duplicated.

(a) `download_file` rescue restructured so the curl fallback short-circuits
cleanly BEFORE the existing retry logic, preserving EXACT non-Windows behavior
for both `Down::Error` and any bare `Errno::ENOTSOCK`:

```ruby
def download_file
  @tries ||= 0
  @tries += 1
  print_download_start if @verbose
  do_download_file
rescue => e
  return curl_download if CurlDownloader.fallback?(e)
  raise unless e.is_a?(Down::Error)

  if @tries < max_retries
    sleep(backoff_time(@tries))
    retry
  end

  raise Fontist::Errors::InvalidResourceError,
        "Invalid URL: #{@file}. Error: #{e.inspect}."
end
```

Note: the bare `rescue => e` now catches everything, but `raise unless
e.is_a?(Down::Error)` re-raises any non-Down, non-fallback error immediately,
so off-Windows behavior is identical to today (Down::Error retries; everything
else propagates unchanged — today a bare non-Down error already escaped the
`rescue Down::Error`).

(b) `github_aware_url(raw_url)`: wrap the
`GitHubClient.authenticated_download_url(parsed)` call so that when it raises the
ENOTSOCK signature on Windows, we return `raw_url` (which is the
`releases/download/...` form; curl's `-L` resolves the redirect itself).
Re-raise otherwise. `GitHubClient` stays untouched.

```ruby
def github_aware_url(raw_url)
  parsed = GitHubUrl.parse(raw_url)
  return raw_url unless parsed.matched?

  GitHubClient.authenticated_download_url(parsed)
rescue => e
  raise unless CurlDownloader.fallback?(e)

  raw_url
end
```

(c) New private `curl_download` helper:

```ruby
def curl_download
  CurlDownloader.new(url, user_agent: headers["User-Agent"]).download
end
```

`curl_download` is called from inside `download_file`, which is the block passed
to `@cache.fetch` in `download`; the curl Tempfile therefore flows through the
exact same `@cache.fetch` (move/extension) + `check_tampered` (SHA256) path as a
normal Down result. No SHA logic is reimplemented.

### 3. NEW `spec/fontist/utils/curl_downloader_spec.rb`

All off-Windows (real ENOTSOCK can't be reproduced here), by stubbing
`Gem.win_platform?` and the runner. Covers:

- `.fallback?` gating: true ONLY when `Gem.win_platform?` is true AND the error
  is an ENOTSOCK signature; false when platform is non-Windows even with an
  ENOTSOCK error; false when platform is Windows but the error is unrelated
  (e.g. `Down::NotFound`).
- `.enotsock?` TYPED path: true for a bare `Errno::ENOTSOCK`; true for an error
  whose `#cause` chain contains `Errno::ENOTSOCK`; tested SEPARATELY from...
- `.enotsock?` MESSAGE-ONLY path: true for a `Down::ConnectionError` (no typed
  cause) whose message contains "not a socket" / "ENOTSOCK"; false for an
  unrelated message.
- `#argv` construction: starts with `curl.exe -fSL --retry 3`, includes
  `-A <user_agent>`, `-o <path>`, and the URL placed AFTER `--` (assert the URL
  never appears before `--`, i.e. no flag injection).
- A non-zero curl exit raises `Fontist::Errors::InvalidResourceError`
  (stub `Open3.capture3`).

### 4. `spec/fontist/utils/downloader_spec.rb` (small addition — new context only)

A focused context proving the curl path still runs SHA verification:

- Stub `Gem.win_platform?` to true and make `Down.download` raise an
  ENOTSOCK-signature error; stub `CurlDownloader#download` to return a fixture
  Tempfile. Assert the downloader takes the curl path (no retry burned) AND that
  `check_tampered` still fires (SHA mismatch warning on `Fontist.ui.error`).
- Stub `Gem.win_platform?` to false with the same error: existing
  retry-then-`InvalidResourceError` behavior, no curl.

This is added as new `context` blocks, NOT a rewrite of the file.

## Test commands

```
bundle exec rspec spec/fontist/utils/curl_downloader_spec.rb \
                  spec/fontist/utils/downloader_spec.rb
bundle exec rubocop lib/fontist/utils/curl_downloader.rb \
                    lib/fontist/utils/downloader.rb \
                    spec/fontist/utils/curl_downloader_spec.rb
```

## Risks / notes

- Both lib edits are gated strictly by `Gem.win_platform?` via
  `CurlDownloader.fallback?`, so the non-Windows suite (the only one runnable
  here) must show identical behavior; existing downloader specs must still pass.
- Real ENOTSOCK can't be reproduced off-Windows, so the curl runner is stubbed;
  the specs assert the *decision* (platform + signature), the *argv*, and that
  the curl result still flows through SHA verification — which is where the logic
  lives.
- This reframes the earlier "no curl" stance as a Windows-only, signature-gated
  fallback; for user review.
