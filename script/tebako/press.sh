#!/usr/bin/env bash
# Press fontist into one self-contained executable with tebako v2.
#
#   script/tebako/press.sh <tebako-triplet> <output-path>
#
# <tebako-triplet> is the tebako release asset suffix: linux-gnu-x86_64,
# linux-gnu-arm64, macos-arm64 or macos-x86_64. Needs gh, ruby and bundler.
# GH_TOKEN (or GITHUB_TOKEN) keeps tebako's runtime lookups clear of the
# anonymous GitHub API limit.
set -euo pipefail

triplet="${1:?usage: press.sh <tebako-triplet> <output-path>}"
output="${2:?usage: press.sh <tebako-triplet> <output-path>}"

tebako_version="${TEBAKO_VERSION:-2.8.68}"
ruby_version="${PACKAGE_RUBY_VERSION:-3.3.12}"
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

asset="tebako-${tebako_version}-${triplet}"
gh release download "v${tebako_version}" --repo tamatebako/tebako \
  --pattern "${asset}" --pattern "${asset}.sha256" --dir "$work"
(cd "$work" && shasum -a 256 -c "${asset}.sha256")
chmod +x "$work/$asset"

stage="$("$here/stage.sh" "$work/stage")"

mkdir -p "$(dirname "$output")"
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"

# tebako appends a trailer to the executable: never strip the result.
"$work/$asset" press --root "$stage" --entry-point bin/fontist \
  --output "$output" --mode self-contained -R "$ruby_version"
