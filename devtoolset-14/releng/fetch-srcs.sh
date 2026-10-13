#!/bin/bash
# Download upstream source tarballs for devtoolset-14 components and verify SHA512.
# Usage: fetch-srcs.sh <comp|all> [dest]
set -uo pipefail
set +e
COMP="${1:-all}"
DEST="${2:-/build/SOURCES}"
mkdir -p "$DEST"
SRCDIR="${SRCDIR:-/workspace/devtoolset-14}"

# Format: <file>|<koji-pkg>|<ver>|<rel>
KOJI_FALLBACK=()

koji_extract() { # file
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
    binutils-2.35.tar.xz) echo "https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz https://mirrors.ustc.edu.cn/gnu/binutils/binutils-2.35.tar.xz";;
    gdb-10.2.tar.xz) echo "https://sourceware.org/pub/gdb/releases/gdb-10.2.tar.xz https://mirrors.ustc.edu.cn/sourceware/gdb/releases/gdb-10.2.tar.xz";;
    gdb-libstdc++-v3-python-8.1.1-20180626.tar.xz) echo "https://sourceware.org/pub/gdb/releases/gdb-libstdc++-v3-python-8.1.1-20180626.tar.xz";;
    v2.0.4.tar.gz) echo "https://codeload.github.com/intel/libipt/tar.gz/refs/tags/v2.0.4";;
    elfutils-0.182.tar.bz2) echo "https://sourceware.org/pub/elfutils/0.182/elfutils-0.182.tar.bz2 https://mirrors.ustc.edu.cn/sourceware/elfutils/0.182/elfutils-0.182.tar.bz2";;
    dwz-0.12.tar.bz2) echo "https://sourceware.org/pub/dwz/releases/dwz-0.12.tar.bz2";;
    annobin-9.29.tar.xz) echo "https://sourceware.org/pub/annobin/9.29/annobin-9.29.tar.xz https://nickc.fedorapeople.org/annobin-9.29.tar.xz";;
    make-4.2.1.tar.bz2) echo "https://ftp.gnu.org/gnu/make/make-4.2.1.tar.bz2 https://mirrors.ustc.edu.cn/gnu/make/make-4.2.1.tar.bz2";;
    strace-5.7.tar.xz) echo "https://strace.io/files/5.7/strace-5.7.tar.xz https://github.com/strace/strace/releases/download/v5.7/strace-5.7.tar.xz";;
    valgrind-3.17.0.tar.bz2) echo "https://sourceware.org/pub/valgrind/valgrind-3.17.0.tar.bz2";;
    systemtap-4.5.tar.gz) echo "https://sourceware.org/pub/systemtap/releases/systemtap-4.5.tar.gz";;
    dyninst-11.0.0.tar.gz) echo "https://codeload.github.com/dyninst/dyninst/tar.gz/refs/tags/v11.0.0";;
    testsuite-11.0.0.tar.gz) echo "https://codeload.github.com/dyninst/testsuite/tar.gz/refs/tags/11.0.0";;
    oprofile-1.4.0.tar.gz) echo "https://downloads.sourceforge.net/oprofile/oprofile-1.4.0.tar.gz https://sourceforge.net/projects/oprofile/files/oprofile/oprofile-1.4.0/oprofile-1.4.0.tar.gz/download";;
    memstomp-38573e7d.tar.gz) echo "https://codeload.github.com/wcohen/memstomp/tar.gz/38573e7d";;
    make-4.4.1.tar.gz) echo "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz https://mirrors.ustc.edu.cn/gnu/make/make-4.4.1.tar.gz";;
    automake-1.16.1.tar.xz) echo "https://ftp.gnu.org/gnu/automake/automake-1.16.1.tar.xz https://mirrors.ustc.edu.cn/gnu/automake/automake-1.16.1.tar.xz";;
    # EL10 baseline (Rocky Linux 10)
    annobin-13.02.tar.xz) echo "https://nickc.fedorapeople.org/annobin-13.02.tar.xz";;
    binutils-2.41.tar.xz) echo "https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz https://mirrors.ustc.edu.cn/gnu/binutils/binutils-2.41.tar.xz";;
    dwz-0.16.tar.xz) echo "https://sourceware.org/pub/dwz/releases/dwz-0.16.tar.xz";;
    dyninst-13.0.0.tar.gz) echo "https://codeload.github.com/dyninst/dyninst/tar.gz/refs/tags/v13.0.0";;
    elfutils-0.194.tar.bz2) echo "https://sourceware.org/pub/elfutils/0.194/elfutils-0.194.tar.bz2 https://mirrors.ustc.edu.cn/sourceware/elfutils/0.194/elfutils-0.194.tar.bz2";;
    gdb-16.3.tar.xz) echo "https://sourceware.org/pub/gdb/releases/gdb-16.3.tar.xz https://mirrors.ustc.edu.cn/sourceware/gdb/releases/gdb-16.3.tar.xz https://mirror.sjtu.edu.cn/gnu/gdb/gdb-16.3.tar.xz";;
    strace-6.12.tar.xz) echo "https://strace.io/files/6.12/strace-6.12.tar.xz https://github.com/strace/strace/releases/download/v6.12/strace-6.12.tar.xz";;
    systemtap-5.4.tar.gz) echo "https://sourceware.org/pub/systemtap/releases/systemtap-5.4.tar.gz";;
    valgrind-3.26.0.tar.bz2) echo "https://sourceware.org/pub/valgrind/valgrind-3.26.0.tar.bz2";;
    standards.info.gz) echo "https://ftp.gnu.org/gnu/binutils/standards.info.gz";;
    xxhash-0.8.2.tar.gz) echo "https://github.com/Cyan4973/xxHash/archive/v0.8.2/xxhash-0.8.2.tar.gz";;
    babeltrace-1.5.11.tar.bz2) echo "https://src.fedoraproject.org/repo/pkgs/babeltrace/babeltrace-1.5.11.tar.bz2/sha512/a3158bb9d0306c1cab6ac3d16ba542605ad60b13ecb10fe740a3b95168f0ead87d31483a06d49a15341f7ef6def16765d9a6045f40a60cd8b94070d979c0c3d1/babeltrace-1.5.11.tar.bz2 https://www.efficios.com/files/babeltrace/babeltrace-1.5.11.tar.bz2";;
    boost_1_83_0.tar.bz2) echo "https://boostorg.jfrog.io/artifactory/main/release/1.83.0/source/boost_1_83_0.tar.bz2 https://sourceforge.net/projects/boost/files/boost/1.83.0/boost_1_83_0.tar.bz2/download";;
    gts-annobin-plugin-select.sh) echo "https://sources.stream.centos.org/sources/rpms/gcc-toolset-14/gts-annobin-plugin-select.sh/sha512/f5e5f4dc054bdd09c6d185bc3c671376ff8b825c8fa3f2969e25e10358405aa105f74154c63b6dc025cbe7e09eb24693664048685aaf481cc2a65d12ad9476b8/gts-annobin-plugin-select.sh";;
    README) echo "https://sources.stream.centos.org/sources/rpms/gcc-toolset-14/README/sha512/a4ed9ea6bb2cdc32cc908cdaf56faf6a813712c2b807a31e286a5fa2faead5285be025363b66d699e30afe34213c66421b76321ef0ca7b57e5e3c5610d32c3c8/README";;
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
    curl -fL --retry 3 --retry-delay 5 --connect-timeout 30 --max-time 1800 \
         -o "$DEST/$fn.part" "$u" 2>&1 | tail -3
    if [ -s "$DEST/$fn.part" ]; then
      local got; got=$(sha512_of "$DEST/$fn.part")
      if [ -z "$want" ]; then mv "$DEST/$fn.part" "$DEST/$fn"; echo "  ok $fn (unverified)"; return 0; fi
      if [ "$got" = "$want" ]; then mv "$DEST/$fn.part" "$DEST/$fn"; echo "  ok $fn"; return 0; fi
      echo "  !! sha mismatch: got $got want $want"
    fi
    rm -f "$DEST/$fn.part"
  done
  echo "  !! FAILED $fn"; return 1
}

fetch_for() {
  local comp="$1"
  local src="$SRCDIR/specs/$comp-el7/sources"
  [ -f "$src" ] || src="$SRCDIR/specs/$comp-el10/sources"
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
  for c in binutils gdb elfutils dwz annobin strace ltrace valgrind systemtap dyninst; do fetch_for "$c"; done
else
  fetch_for "$COMP"
fi
