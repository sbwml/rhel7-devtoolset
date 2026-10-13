#!/bin/bash
# Build devtoolset-16 meta packages (toolchain / runtime / build).
set -uo pipefail
SRCDIR="${SRCDIR:-/workspace/devtoolset-16}"
OUT="${OUT:-/out}"
BUILD_ROOT="${BUILD_ROOT:-/build}"

source "$SRCDIR/releng/ci-common.sh"
set +e

log "===== build meta devtoolset-16 ====="
setup_repos; install_toolchain; setup_dirs

SPEC=$(prepare_spec meta) || { echo "!! prepare_spec failed"; exit 1; }
log "spec: $SPEC"
log "---- spec head ----"; sed -n '1,20p' "$SPEC"

bash "$SRCDIR/releng/fetch-srcs.sh" meta "$BUILD_ROOT/SOURCES" 2>&1 | tail -20

log "rpmbuild -ba $SPEC"
( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] meta building..."; done ) &
HB=$!
scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$SPEC'" 2>&1 | tee "$OUT/logs/meta.log"
rc=${PIPESTATUS[0]}
kill "$HB" 2>/dev/null || true
log "rpmbuild rc=$rc"

log "artifacts:"
find "$OUT" -name '*devtoolset-16*.rpm' -printf '%s %p\n' | sort -n
exit $rc
