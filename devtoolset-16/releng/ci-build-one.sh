#!/bin/bash
# Build a single devtoolset-16 component.
# Usage: ci-build-one.sh <comp>
set -uo pipefail
COMP="${1:?component}"
SRCDIR="${SRCDIR:-/workspace/devtoolset-16}"
OUT="${OUT:-/out}"
BUILD_ROOT="${BUILD_ROOT:-/build}"

source "$SRCDIR/releng/ci-common.sh"
set +e

log "===== build $COMP ====="
setup_repos; install_toolchain; setup_dirs
log "toolchain: $(scl enable devtoolset-12 'gcc -v' 2>&1 | tail -1)"

SPEC=$(prepare_spec "$COMP") || { echo "!! prepare_spec failed"; exit 1; }
log "spec: $SPEC"

log "fetch sources"
if [ "$COMP" = "gcc" ]; then
  bash "$SRCDIR/releng/fetch-gcc-srcs.sh" "$BUILD_ROOT/SOURCES" 2>&1 | tail -40
else
  bash "$SRCDIR/releng/fetch-srcs.sh" "$COMP" "$BUILD_ROOT/SOURCES" 2>&1 | tail -40
fi

install_built_prereqs "$COMP"

log "rpmbuild -ba $SPEC"
( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] $COMP building..."; done ) &
HB=$!
scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$SPEC'" 2>&1 | tee "$OUT/logs/$COMP.log"
rc=${PIPESTATUS[0]}
kill "$HB" 2>/dev/null || true
log "rpmbuild rc=$rc"

log "artifacts:"
find "$OUT" -name '*.rpm' -printf '%s %p\n' | sort -n
exit $rc
