#!/usr/bin/env bash
# Get git >= 2.43 on an older Debian or Ubuntu, the documented one-time step
# before installing the fontist .deb (see README.adoc). Run as root.
#
#   script/tebako/git-prep.sh
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
# shellcheck disable=SC1091
. /etc/os-release

apt-get update -qq
case "$ID:$VERSION_ID" in
  ubuntu:22.04)
    apt-get install -y -qq ca-certificates software-properties-common
    add-apt-repository -y ppa:git-core/ppa
    apt-get update -qq
    apt-get install -y -qq git
    ;;
  debian:12)
    apt-get install -y -qq ca-certificates
    echo 'deb http://deb.debian.org/debian bookworm-backports main' \
      > /etc/apt/sources.list.d/bookworm-backports.list
    apt-get update -qq
    apt-get install -y -qq -t bookworm-backports git
    ;;
  *)
    echo "git-prep: nothing to do on $ID $VERSION_ID" >&2
    exit 1
    ;;
esac
git --version
