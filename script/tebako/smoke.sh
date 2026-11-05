#!/usr/bin/env bash
# Check that a packed (or installed) fontist works on its own.
#
#   script/tebako/smoke.sh <fontist-executable>
#
# Uses a throwaway FONTIST_PATH so it never touches a real ~/.fontist.
set -euo pipefail

fontist="${1:?usage: smoke.sh <fontist-executable>}"
font="${SMOKE_FONT:-Overpass}"

home="$(mktemp -d)"
trap 'rm -rf "$home"' EXIT
export FONTIST_PATH="$home"

"$fontist" version
"$fontist" install --accept-all-licenses "$font"

if ! find "$home/fonts" -type f | grep -q .; then
  echo "smoke: no font file landed under $home/fonts" >&2
  exit 1
fi
"$fontist" list "$font" | tee "$home/list.txt"
grep -qi "installed" "$home/list.txt"
echo "smoke: ok"
