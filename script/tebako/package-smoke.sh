#!/usr/bin/env bash
# Install a fontist .deb or .rpm on a fresh distro, use it, then remove it.
# Runs inside a distro container (see .github/workflows/tebako-pack.yml).
#
#   script/tebako/package-smoke.sh <package-dir>
set -euo pipefail

dir="${1:?usage: package-smoke.sh <package-dir>}"
# apt reads a bare relative path as a package name; give it an absolute one.
dir="$(cd "$dir" && pwd)"
here="$(cd "$(dirname "$0")" && pwd)"

if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq ca-certificates "$dir"/fontist_*.deb
  remove() { apt-get remove -y -qq fontist; }
else
  dnf install -y -q "$dir"/fontist-*.rpm
  remove() { dnf remove -y -q fontist; }
fi

if command -v ruby >/dev/null; then
  echo "package-smoke: this image has no business carrying ruby" >&2
  exit 1
fi
link="$(readlink /usr/local/bin/fontist || true)"
if [ "$link" != /usr/lib/fontist/fontist ]; then
  echo "package-smoke: /usr/local/bin/fontist links to '$link'" >&2
  exit 1
fi
"$here/smoke.sh" "$(command -v fontist)"
remove
if [ -e /usr/local/bin/fontist ] || [ -L /usr/local/bin/fontist ] || command -v fontist >/dev/null; then
  echo "package-smoke: fontist still present after removal" >&2
  exit 1
fi
echo "package-smoke: ok"
