#!/usr/bin/env bash
# Build a Gemfile-rooted app around the fontist gem, the layout tebako v2
# presses (it refuses a root that is itself a gem source tree).
#
#   script/tebako/stage.sh <stage-dir>
#
# The gem is built from this checkout, unpacked with a static gemspec (the
# repository gemspec lists files with `git ls-files`, which needs .git), and
# referenced by path, so the packed fontist is exactly this checkout's code.
set -euo pipefail

stage="${1:?usage: stage.sh <stage-dir>}"
root="$(cd "$(dirname "$0")/../.." && pwd)"

rm -rf "$stage"
mkdir -p "$stage/vendor" "$stage/bin"
stage="$(cd "$stage" && pwd)"

(cd "$root" && gem build fontist.gemspec --output "$stage/fontist.gem" >/dev/null)
# Unpacked directory naming differs across rubygems versions; take the one
# child of a fresh directory instead of guessing it.
unpacked="$(mktemp -d)"
gem unpack "$stage/fontist.gem" --target "$unpacked" >/dev/null
mv "$unpacked"/*/ "$stage/vendor/fontist"
rmdir "$unpacked"
gem spec "$stage/fontist.gem" --ruby > "$stage/vendor/fontist/fontist.gemspec"
rm "$stage/fontist.gem"

cat > "$stage/Gemfile" <<'GEMFILE'
source "https://rubygems.org"

gem "fontist", path: "vendor/fontist"
GEMFILE

cp "$root/script/tebako/entry.rb" "$stage/bin/fontist"
chmod +x "$stage/bin/fontist"

(cd "$stage" && bundle lock >/dev/null)
echo "$stage"
