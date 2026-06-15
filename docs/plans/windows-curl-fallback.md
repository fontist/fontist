# Windows-only `curl.exe` fallback for downloads

## Goal

When running on Windows and the Ruby `Net::HTTP`/OpenSSL socket layer raises an
`Errno::ENOTSOCK` (confirmed MinGW/servercore:ltsc2025 defect), fall back to
`curl.exe` for both the GitHub asset-URL resolution and the actual download,
leaving all non-Windows behavior byte-for-byte unchanged.

## Root cause (confirmed, not re-investigated)

On Windows Server 2025 containers with RubyInstaller/MinGW Ruby, every outbound
HTTPS through `Net::HTTP`/OpenSSL fails with `Errno::ENOTSOCK` at
`SSLSocket#connect_nonblock`. Plain `TCPSocket` and native `curl.exe` both work.
This affects two code paths in fontist:

1. The download itself — `Down.download` in `Downloader#do_download_file_with_progress_bar`.
2. GitHub release-asset URL **resolution** — `GitHubClient.authenticated_download_url`
   (Octokit -> Faraday -> Net::HTTP), which ENOTSOCKs *before* any download for
   `github.com/.../releases/download/...` URLs.

The Down failure surfaces wrapped as `Down::ConnectionError` (message contains
"not a socket" / "SSL_connect"); the Octokit failure surfaces as a bare
`Errno::ENOTSOCK` (or a `Faraday::ConnectionFailed`/`Octokit::Error` wrapping it).

## Scope

IN scope:
- A small, focused Windows-only curl fallback used **only** when (a) `Gem.win_platform?`
  and (b) the Ruby path raised a failure whose signature is `Errno::ENOTSOCK`.
- Cover both the download path and the GitHub-URL-resolution path.

OUT of scope (do NOT touch):
- Any non-Windows behavior.
- The retry/backoff loop semantics for non-ENOTSOCK errors.
- Progress-bar accuracy for the curl path (a no-op/Null bar is fine).
- Migrating away from Down/Octokit in general; this is a guarded fallback only.
- Existing unrelated downloader/cache bugs.
- README/CHANGELOG.

## Files to touch (4: 2 lib + 1 new lib + 1 spec)

### 1. NEW `lib/fontist/utils/curl_downloader.rb`

A tiny value-object-ish class that knows how to: detect the ENOTSOCK signature,
build the curl argv, and run curl to a temp file. Pure-ish; the only I/O is the
`system`/`Open3` call and tempfile creation.

```ruby
module Fontist
  module Utils
    class CurlDownloader
      CURL = "curl.exe".freeze

      # True when this is the confirmed MinGW ENOTSOCK socket-handoff defect,
      # in any of its wrapped forms.
      def self.enotsock?(error)
        return true if error.is_a?(Errno::ENOTSOCK)

        cause = error
        while cause
          return true if cause.is_a?(Errno::ENOTSOCK)
          msg = cause.message.to_s
          return true if msg.include?("not a socket") || msg.include?("ENOTSOCK")
          cause = cause.cause
        end
        false
      end

      def self.available?
        Gem.win_platform?
      end

      def initialize(url, headers: {})
        @url = url
        @headers = headers
      end

      # Downloads to a fresh Tempfile and returns it (closed-for-write,
      # responding to #path / #original_filename / #content_type) so the
      # existing Cache#move + extension logic keeps working.
      def download
        tempfile = Tempfile.new(...)  # binmode
        run(argv(tempfile.path))      # raise InvalidResourceError on non-zero
        decorate(tempfile)
      end

      def argv(output_path)
        cmd = [CURL, "-fSL", "--retry", "3", "-o", output_path]
        @headers.each { |k, v| cmd.push("-H", "#{k}: #{v}") }
        cmd.push("--", @url)
      end
      ...
    end
  end
end
```

- argv built as an array; URL passed after `--` so it is never treated as a flag.
- `-f` fail on HTTP >= 400, `-S` show errors, `-L` follow redirects, `--retry 3`.
- Header flags carry the same browser User-Agent etc. that Down would send.
- On non-zero exit -> raise `Fontist::Errors::InvalidResourceError`.
- Returns a Tempfile decorated with `original_filename` (basename from resolved
  URL path) and `content_type` (nil — cache falls back to the filename's
  extension, which font asset URLs always have).

### 2. `lib/fontist/utils/downloader.rb`

- In `download_file`: keep the existing `rescue Down::Error` retry/backoff path
  unchanged for the normal case. Add an **earlier, immediate** fallback: if the
  raised error is the ENOTSOCK signature AND `CurlDownloader.available?`, do the
  curl download immediately (skip burning the retry budget). The returned file
  flows through the same `@cache.fetch` + `check_tampered` path because the
  fallback is invoked from inside `download_file` / `do_download_file`, before
  the file leaves the cache block.

  Concretely: rescue both `Down::Error` and `Errno::ENOTSOCK`; if
  `CurlDownloader.enotsock?(e) && CurlDownloader.available?`, return
  `curl_download` (no retry); else keep existing retry/raise behavior.

- In `github_aware_url`: for a matched GitHub release-download URL on Windows,
  the Octokit resolution will ENOTSOCK. Wrap `GitHubClient.authenticated_download_url`
  so that when it raises the ENOTSOCK signature on Windows, we fall back to the
  raw `/releases/download/<tag>/<asset>` URL directly (curl's `-L` handles the
  redirect to the asset host). Non-Windows path unchanged.

  Minimal change: only github.com release URLs already match `GitHubUrl`, and the
  `original_url` IS the `/releases/download/...` form, so the fallback is simply
  "return `parsed.original_url` when resolution ENOTSOCKs on Windows."

- Add private `curl_download` helper that constructs `CurlDownloader.new(url,
  headers: headers).download`.

### 3. `lib/fontist/utils/github_client.rb`

- `authenticated_download_url` currently rescues only `Octokit::Error`. The
  ENOTSOCK can surface as `Errno::ENOTSOCK` / `Faraday::ConnectionFailed` which
  are NOT `Octokit::Error`, so they'd escape. On Windows, rescue the ENOTSOCK
  signature too and return `parsed_url.original_url` (the direct
  `/releases/download/...` URL). Use `CurlDownloader.enotsock?` for the signature
  check to avoid duplicating logic. Non-Windows behavior unchanged (only triggers
  under `CurlDownloader.available?`).

### 4. NEW `spec/fontist/utils/curl_downloader_spec.rb`

Covers (all off-Windows, by stubbing the platform + Ruby-path failure):
- `enotsock?`: true for bare `Errno::ENOTSOCK`, true for a wrapped error whose
  message contains "not a socket", true via `#cause` chain, false for an
  unrelated error (`Down::NotFound`, `Down::TimeoutError`).
- `available?`: gated on `Gem.win_platform?` (stub both true/false).
- `argv`: includes `curl.exe -fSL --retry 3 -o <path>`, a `-H` per header,
  and the URL placed after `--`; URL never appears before `--` (no flag injection).
- That a non-zero curl exit raises `Fontist::Errors::InvalidResourceError`
  (stub the runner).

Plus, in the existing `downloader_spec.rb` (touched as part of file #2's tests,
but kept minimal — added as a new `context` block, not a rewrite):
- When `Down.download` raises an ENOTSOCK-signature error AND the platform is
  stubbed to Windows, the downloader invokes the curl path (stubbed) instead of
  retrying, and the result still goes through `check_tampered`
  (SHA verification runs — assert mismatch warning fires).
- When the same error is raised but platform is NOT Windows, behavior is the
  existing retry-then-`InvalidResourceError` (no curl).

(Whether the downloader assertions live in `downloader_spec.rb` or
`curl_downloader_spec.rb` will be decided at implementation; default is to keep
`CurlDownloader` unit tests in the new spec and the gating/integration tests in
`downloader_spec.rb`. That keeps it to one new spec file + a small addition to an
existing one — still within the 2-3 file + specs budget.)

## Test commands

```
bundle exec rspec spec/fontist/utils/curl_downloader_spec.rb \
                  spec/fontist/utils/downloader_spec.rb
bundle exec rubocop lib/fontist/utils/curl_downloader.rb \
                    lib/fontist/utils/downloader.rb \
                    lib/fontist/utils/github_client.rb
```

## Risks / notes

- The two new lib edits are guarded strictly by `Gem.win_platform?`, so the
  non-Windows suite (the only suite we can run here) must show identical behavior;
  the existing downloader specs must still pass untouched.
- Real ENOTSOCK can't be reproduced off-Windows, so the curl runner itself is
  stubbed in specs; we test the *decision* (platform + signature) and the
  *argv construction*, which is where the logic lives.
