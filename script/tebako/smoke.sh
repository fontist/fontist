#!/usr/bin/env bash
# Check that a packed (or installed) fontist works on its own.
#
#   script/tebako/smoke.sh <fontist-executable>
#
# Uses a throwaway FONTIST_PATH, then a throwaway HOME, so it never touches a
# real ~/.fontist.
set -euo pipefail

fontist="${1:?usage: smoke.sh <fontist-executable>}"
font="${SMOKE_FONT:-Overpass}"

home="$(mktemp -d)"
trap 'rm -rf "$home"' EXIT
export FONTIST_PATH="$home"

"$fontist" --version
"$fontist" version
"$fontist" install --accept-all-licenses "$font"

if ! find "$home/fonts" -type f | grep -q .; then
  echo "smoke: no font file landed under $home/fonts" >&2
  exit 1
fi
"$fontist" list "$font" | tee "$home/list.txt"
grep -qi "installed" "$home/list.txt"

# Without FONTIST_PATH, fonts land in ~/.fontist.
user_home="$(mktemp -d)"
trap 'rm -rf "$home" "$user_home"' EXIT
env -u FONTIST_PATH HOME="$user_home" "$fontist" install --accept-all-licenses "$font"
if ! find "$user_home/.fontist/fonts" -type f | grep -q .; then
  echo "smoke: no font file landed under $user_home/.fontist/fonts" >&2
  exit 1
fi
echo "smoke: ok"
