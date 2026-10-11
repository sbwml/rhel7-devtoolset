#!/bin/bash
# Build devtoolset-14 meta packages (toolchain / perftools / runtime / build).
set -uo pipefail
SRCDIR="${SRCDIR:-/workspace/devtoolset-14}"
OUT="${OUT:-/out}"
BUILD_ROOT="${BUILD_ROOT:-/build}"

source "$SRCDIR/releng/ci-common.sh"
set +e

log "===== build meta devtoolset-14 ====="
setup_repos; install_toolchain; setup_dirs

SPEC=$(prepare_spec meta) || { echo "!! prepare_spec failed"; exit 1; }
log "spec: $SPEC"
log "---- spec head ----"; sed -n '1,20p' "$SPEC"

log "rpmbuild -ba $SPEC"
( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] meta building..."; done ) &
HB=$!
scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$SPEC'" 2>&1 | tee "$OUT/logs/meta.log"
rc=${PIPESTATUS[0]}
kill "$HB" 2>/dev/null || true
log "rpmbuild rc=$rc"

log "artifacts:"
find "$OUT" -name '*devtoolset-14*.rpm' -printf '%s %p\n' | sort -n
exit $rc
