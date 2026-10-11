#!/bin/bash
# Fetch GCC 14.3.1 (el10 / Rocky Linux 10) build sources from Rocky Linux 10 gcc SRPM.
set -uo pipefail
DEST="${1:-/build/SOURCES}"
SRCDIR="${SRCDIR:-/workspace/devtoolset-14}"
SPEC_SRC="${SPEC_SRC:-$SRCDIR/specs/gcc-el10/sources}"
mkdir -p "$DEST"
SHA512() { sha512sum "$1" 2>/dev/null | awk '{print $1}'; }
log() { echo -e "\033[1;36m>>> $*\033[0m"; }

# Rocky Linux 10 BaseOS gcc SRPM (gcc-14.3.1-4.4.el10)
SRPM_URLS=(
  "https://mirror.sjtu.edu.cn/rocky/10/BaseOS/source/tree/Packages/g/gcc-14.3.1-4.4.el10.src.rpm"
  "https://dl.rockylinux.org/vault/rocky/10/BaseOS/source/tree/Packages/g/gcc-14.3.1-4.4.el10.src.rpm"
)
CACHE=/tmp/el10-gcc-srpm
mkdir -p "$CACHE"

SRPM="$CACHE/gcc-14.3.1-4.4.el10.src.rpm"
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

FILES="gcc-14.3.1-20251022.tar.xz isl-0.24.tar.bz2 nvptx-tools-87ce9dc5999e5fca2e1d3478a30888d9864c9804.tar.xz newlib-cygwin-d45261f62a15f8abd94a1031020b9a9f455e4eed.tar.xz"

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
