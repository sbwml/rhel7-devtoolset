#!/bin/bash
# Fetch GCC 16.2.1 (el10 / CentOS Stream 10) build sources from gcc-toolset-16-gcc SRPM.
set -uo pipefail
DEST="${1:-/build/SOURCES}"
SRCDIR="${SRCDIR:-/workspace/devtoolset-16}"
SPEC_SRC="${SPEC_SRC:-$SRCDIR/specs/gcc-el10/sources}"
mkdir -p "$DEST"
SHA512() { sha512sum "$1" 2>/dev/null | awk '{print $1}'; }
log() { echo -e "\033[1;36m>>> $*\033[0m"; }

SRPM_URLS=(
  "https://kojihub.stream.centos.org/kojifiles/packages/gcc-toolset-16-gcc/16.2.1/1.2.el10/src/gcc-toolset-16-gcc-16.2.1-1.2.el10.src.rpm"
  "http://mirror.stream.centos.org/10-stream/AppStream/source/tree/Packages/gcc-toolset-16-gcc-16.2.1-1.2.el10.src.rpm"
)
CACHE=/tmp/el10-gcc16-srpm
mkdir -p "$CACHE"

SRPM="$CACHE/gcc-toolset-16-gcc-16.2.1-1.2.el10.src.rpm"
if [ ! -s "$SRPM" ]; then
  for u in "${SRPM_URLS[@]}"; do
    log "download $u"
    if curl -sfL --max-time 3600 -o "$SRPM.part" "$u"; then
      mv -f "$SRPM.part" "$SRPM"; break
    fi
    rm -f "$SRPM.part"
  done
fi
[ -s "$SRPM" ] || { echo "!! failed to obtain gcc src.rpm"; exit 1; }
log "srpm: $(du -h "$SRPM" | cut -f1)"

FILES="gcc-16.2.1-20260807.tar.xz isl-0.24.tar.bz2 nvptx-tools-212da2e781ed0f9423824e85eb04819958513f7a.tar.xz newlib-cygwin-d35cc82b5ec15bb8a5fe0fe11e183d1887992e99.tar.xz"

MISSING=""
for f in $FILES; do
  w=$(grep -m1 "($f)" "$SPEC_SRC" | sed 's/.*= *//')
  if [ -s "$DEST/$f" ] && [ "$(SHA512 "$DEST/$f")" = "$w" ]; then
    echo "  ok(cached) $f"
  else
    MISSING="$MISSING $f"
  fi
done

if [ -n "$MISSING" ]; then
  log "extract from SRPM:$MISSING"
  ( cd "$CACHE" && rpm2cpio "$SRPM" | cpio -idmu --quiet $MISSING ) 2>/dev/null || true
  ( cd "$CACHE" && rpm2cpio "$SRPM" | cpio -idmu --quiet $(for f in $MISSING; do echo "./$f"; done) ) 2>/dev/null || true
  for f in $MISSING; do
    [ -s "$CACHE/$f" ] && mv -f "$CACHE/$f" "$DEST/$f" || echo "  !! not in srpm: $f"
  done
fi

echo "=== gcc SOURCES ==="
rc=0
for f in $FILES; do
  w=$(grep -m1 "($f)" "$SPEC_SRC" | sed 's/.*= *//')
  if [ -s "$DEST/$f" ] && [ "$(SHA512 "$DEST/$f")" = "$w" ]; then echo "  OK $f"; else echo "  MISSING/BAD $f"; rc=1; fi
done
exit $rc
