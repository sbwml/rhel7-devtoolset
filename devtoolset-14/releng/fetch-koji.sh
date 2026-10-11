#!/bin/bash
# Extract files from CentOS Stream koji SRPM.
# Usage: fetch-koji.sh <koji-pkg-dir> <version-dir> <rel> <file...>
set -uo pipefail
PKG="$1"; VER="$2"; REL="$3"; shift 3
BASE="https://kojihub.stream.centos.org/kojifiles/packages/$PKG/$VER/$REL/src"
DEST="${DEST:-/build/SOURCES}"; mkdir -p "$DEST"
CACHE=/tmp/koji-cache; mkdir -p "$CACHE"
echo "  [koji] $PKG $VER $REL -> $*"

SRPM=$(curl -s --max-time 60 "$BASE/" | grep -oE '[A-Za-z0-9._+-]+\.src\.rpm' | sort -u | head -1)
[ -n "$SRPM" ] || { echo "  !! no srpm listing at $BASE"; exit 1; }
echo "  [koji] srpm=$SRPM"
if [ ! -s "$CACHE/$SRPM" ]; then
  if ! curl -sfL --max-time 1800 -o "$CACHE/$SRPM.part" "$BASE/$SRPM"; then
    echo "  !! srpm download failed"; rm -f "$CACHE/$SRPM.part"; exit 1
  fi
  mv -f "$CACHE/$SRPM.part" "$CACHE/$SRPM"
fi

rc=0
for f in "$@"; do
  if [ -s "$DEST/$f" ]; then echo "  ok(cached) $f"; continue; fi
  ( cd "$CACHE" && rpm2cpio "$SRPM" | cpio -idmu --quiet "./$f" ) 2>/dev/null
  if [ ! -f "$CACHE/$f" ]; then
    ( cd "$CACHE" && rpm2cpio "$SRPM" | cpio -idmu --quiet "$f" ) 2>/dev/null
  fi
  if [ -f "$CACHE/$f" ]; then
    mv -f "$CACHE/$f" "$DEST/$f"; echo "  extracted $f"
  else
    echo "  !! not in srpm: $f"; rc=1
  fi
done
exit $rc
