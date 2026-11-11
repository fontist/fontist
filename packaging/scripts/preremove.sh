#!/bin/sh
# Remove the /usr/local/bin symlink on removal, not on upgrade. dpkg passes
# "remove" or "purge"; rpm passes the number of copies left (0 on removal).
set -e
case "$1" in
  remove|purge|0)
    if [ "$(readlink /usr/local/bin/fontist 2>/dev/null)" = /usr/lib/fontist/fontist ]; then
      rm -f /usr/local/bin/fontist
    fi
    ;;
esac
exit 0
