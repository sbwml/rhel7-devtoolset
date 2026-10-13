#!/bin/bash
# Build multiple devtoolset-14 components specified in COMPS.
set -uo pipefail
SRCDIR="${SRCDIR:-/workspace/devtoolset-14}"
OUT="${OUT:-/out}"; BUILD_ROOT="${BUILD_ROOT:-/build}"
source "$SRCDIR/releng/ci-common.sh"; set +e
setup_repos; install_toolchain; setup_dirs
log "toolchain: $(scl enable devtoolset-12 'gcc -v' 2>&1 | tail -1)"
ensure_autoconf || log "!! ensure_autoconf failed, falling back to system autoconf"
ensure_automake || log "!! ensure_automake failed, falling back to system automake"
LIST=$(echo "${COMPS:-make}" | tr ',' ' ')
declare -A RC
for COMP in $LIST; do
  log "########## $COMP ##########"
  SPEC=$(prepare_spec "$COMP") || { echo "!! prepare failed"; RC[$COMP]=1; continue; }
  if [ "$COMP" = "gcc" ]; then
    bash "$SRCDIR/releng/fetch-gcc-srcs.sh" "$BUILD_ROOT/SOURCES" 2>&1 | tail -30
  else
    bash "$SRCDIR/releng/fetch-srcs.sh" "$COMP" "$BUILD_ROOT/SOURCES" 2>&1 | tail -30
  fi
  install_built_prereqs "$COMP"
  ( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] $COMP building..."; done ) &
  HB=$!
  scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$SPEC'" 2>&1 | tee "$OUT/logs/$COMP.log"
  rc=${PIPESTATUS[0]}
  kill "$HB" 2>/dev/null || true
  RC[$COMP]=$rc; echo ">>> $COMP rc=$rc"
  grep -iE "error:|Error [0-9]|undefined reference|No such file" "$OUT/logs/$COMP.log" | tail -10
done
log "===== SUMMARY ====="
for c in $LIST; do printf '%-12s rc=%s\n' "$c" "${RC[$c]:-?}"; done
