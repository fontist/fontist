#!/usr/bin/env bash
# Wrap a packed Linux fontist executable into .deb and .rpm packages.
#
#   script/tebako/package.sh <amd64|arm64> <fontist-executable> <out-dir>
set -euo pipefail

usage="usage: package.sh <amd64|arm64> <fontist-executable> <out-dir>"
arch="${1:?$usage}"
binary="${2:?$usage}"
out="${3:?$usage}"

root="$(cd "$(dirname "$0")/../.." && pwd)"
version="$(sed -n 's/.*VERSION = "\(.*\)".*/\1/p' "$root/lib/fontist/version.rb")"

mkdir -p "$out"
BINARY="$(cd "$(dirname "$binary")" && pwd)/$(basename "$binary")"
export ARCH="$arch" VERSION="$version" BINARY

for packager in deb rpm; do
  nfpm package --config "$root/packaging/nfpm.yaml" \
    --packager "$packager" --target "$out"
done
ls -l "$out"
