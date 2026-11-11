#!/bin/sh
# The binary lives in /usr/lib/fontist; make it reachable from /usr/local/bin.
set -e
mkdir -p /usr/local/bin
ln -sf /usr/lib/fontist/fontist /usr/local/bin/fontist
