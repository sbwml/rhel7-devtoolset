#!/bin/bash
# Build all devtoolset-14 dependency packages.
set -uo pipefail
SRCDIR="${SRCDIR:-/workspace/devtoolset-14}"
OUT="${OUT:-/out}"
BUILD_ROOT="${BUILD_ROOT:-/build}"

source "$SRCDIR/releng/ci-common.sh"
set +e

setup_repos; install_toolchain; setup_dirs
log "toolchain: $(scl enable devtoolset-12 'gcc -v' 2>&1 | tail -1)"
ensure_automake || log "!! ensure_automake failed, falling back to system automake"

ORDER="xxhash babeltrace boost183 dwz ltrace strace make annobin elfutils binutils valgrind dyninst systemtap gdb"

declare -A RC
for COMP in $ORDER; do
  log "########## $COMP ##########"
  SPEC=$(prepare_spec "$COMP") || { echo "!! prepare failed $COMP"; RC[$COMP]=1; continue; }
  bash "$SRCDIR/releng/fetch-srcs.sh" "$COMP" "$BUILD_ROOT/SOURCES" 2>&1 | tail -20
  install_built_prereqs "$COMP"
  ( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] $COMP building..."; done ) &
  HB=$!
  scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$SPEC'" 2>&1 | tee "$OUT/logs/$COMP.log"
  rc=${PIPESTATUS[0]}
  kill "$HB" 2>/dev/null || true
  RC[$COMP]=$rc
  echo ">>> $COMP rc=$rc"
done

log "===== SUMMARY ====="
for c in $ORDER; do printf '%-12s rc=%s\n' "$c" "${RC[$c]:-?}"; done
log "===== ALL RPM ====="
find "$OUT" -name '*.rpm' -printf '%s %p\n' | sort -n
