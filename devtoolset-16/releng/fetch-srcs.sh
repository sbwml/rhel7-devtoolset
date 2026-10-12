#!/bin/bash
# Download upstream source tarballs for devtoolset-16 components and verify SHA512.
# Usage: fetch-srcs.sh <comp|all> [dest]
set -uo pipefail
set +e
COMP="${1:-all}"
DEST="${2:-/build/SOURCES}"
mkdir -p "$DEST"
SRCDIR="${SRCDIR:-/workspace/devtoolset-16}"
CACHE=/tmp/koji-cache
mkdir -p "$CACHE"

# Format: <file>|<koji-pkg>|<ver>|<rel>
KOJI_FALLBACK=(
  "binutils-with-gold-2.46.tar.xz|gcc-toolset-16-binutils|2.46|3.el10"
)

koji_extract() {
  local f="$1" line
  for line in "${KOJI_FALLBACK[@]}"; do
    local fn pkg ver rel
    IFS='|' read -r fn pkg ver rel <<< "$line"
    [ "$fn" = "$f" ] || continue
    echo "  [koji-fallback] $f <- $pkg/$ver/$rel"
    DEST="$DEST" bash "$SRCDIR/releng/fetch-koji.sh" "$pkg" "$ver" "$rel" "$f"
    return $?
  done
  return 2
}

urls_for() {
  case "$1" in
    binutils-with-gold-2.46.tar.xz)
      echo "https://kojihub.stream.centos.org/kojifiles/packages/gcc-toolset-16-binutils/2.46/3.el10/src/gcc-toolset-16-binutils-2.46-3.el10.src.rpm"
      ;;
    gts-annobin-plugin-select.sh)
      echo "https://sources.stream.centos.org/sources/rpms/gcc-toolset-16/gts-annobin-plugin-select.sh/sha512/f5e5f4dc054bdd09c6d185bc3c671376ff8b825c8fa3f2969e25e10358405aa105f74154c63b6dc025cbe7e09eb24693664048685aaf481cc2a65d12ad9476b8/gts-annobin-plugin-select.sh"
      ;;
    *) echo "";;
  esac
}

sha512_of() { sha512sum "$1" 2>/dev/null | awk '{print $1}'; }

fetch_one() {
  local comp="$1" fn="$2" want="$3"
  if [ -f "$DEST/$fn" ] && [ "$(sha512_of "$DEST/$fn")" = "$want" ]; then
    echo "  ok(cached) $fn"; return 0
  fi
  local urls; urls=$(urls_for "$fn")
  if [ -z "$urls" ]; then
    koji_extract "$fn" && { [ "$(sha512_of "$DEST/$fn")" = "$want" ] && { echo "  ok(koji) $fn"; return 0; }; }
    echo "  ?? no URL for $fn"; return 1
  fi
  for u in $urls; do
    echo "  -> $u"
    if [[ "$u" =~ \.src\.rpm$ ]]; then
      local srpm_name; srpm_name=$(basename "$u")
      if [ ! -s "$CACHE/$srpm_name" ]; then
        curl -fL --retry 3 --retry-delay 5 --connect-timeout 30 --max-time 1800 -o "$CACHE/$srpm_name.part" "$u"
        mv -f "$CACHE/$srpm_name.part" "$CACHE/$srpm_name"
      fi
      ( cd "$CACHE" && rpm2cpio "$srpm_name" | cpio -idmu --quiet "$fn" ) 2>/dev/null || true
      if [ -f "$CACHE/$fn" ]; then
        mv -f "$CACHE/$fn" "$DEST/$fn"
        local got; got=$(sha512_of "$DEST/$fn")
        if [ -z "$want" ] || [ "$got" = "$want" ]; then echo "  ok $fn"; return 0; fi
      fi
    else
      curl -fL --retry 3 --retry-delay 5 --connect-timeout 30 --max-time 1800 \
           -o "$DEST/$fn.part" "$u" 2>&1 | tail -3
      if [ -s "$DEST/$fn.part" ]; then
        local got; got=$(sha512_of "$DEST/$fn.part")
        if [ -z "$want" ]; then mv "$DEST/$fn.part" "$DEST/$fn"; echo "  ok $fn (unverified)"; return 0; fi
        if [ "$got" = "$want" ]; then mv "$DEST/$fn.part" "$DEST/$fn"; echo "  ok $fn"; return 0; fi
        echo "  !! sha mismatch: got $got want $want"
      fi
      rm -f "$DEST/$fn.part"
    fi
  done
  echo "  !! FAILED $fn"; return 1
}

fetch_for() {
  local comp="$1"
  local src="$SRCDIR/specs/$comp-el10/sources"
  [ -f "$src" ] || src="$SRCDIR/specs/$comp/sources"
  [ -f "$src" ] || { echo "!! no sources: $comp"; return 1; }
  echo "=== fetch: $comp"
  while IFS= read -r line; do
    local fn want
    fn=$(printf '%s' "$line" | sed -n 's/^NOSHA512 *( *\([^) ]*\) *).*/\1/p')
    if [ -n "$fn" ]; then fetch_one "$comp" "$fn" ""; continue; fi
    fn=$(printf '%s' "$line" | sed -n 's/^SHA512[^(]*( *\([^) ]*\) *).*/\1/p')
    want=$(printf '%s' "$line" | sed -n 's/^SHA512.*= *\([0-9a-fA-F]*\).*/\1/p')
    [ -n "$fn" ] && fetch_one "$comp" "$fn" "$want"
  done < "$src"
}

if [ "$COMP" = "all" ]; then
  for c in binutils gcc meta; do
    if [ "$c" = "gcc" ]; then
      bash "$SRCDIR/releng/fetch-gcc-srcs.sh" "$DEST"
    else
      fetch_for "$c"
    fi
  done
else
  if [ "$COMP" = "gcc" ]; then
    bash "$SRCDIR/releng/fetch-gcc-srcs.sh" "$DEST"
  else
    fetch_for "$COMP"
  fi
fi
