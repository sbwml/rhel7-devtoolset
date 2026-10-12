#!/bin/bash
# Build all devtoolset-16 components and create release archive.
#
# Usage:
#   RELEASE_TAG=16.2.1 bash releng/ci-release.sh            # Full build + archive
#   RELEASE_TAG=16.2.1 RELEASE=0 bash releng/ci-release.sh  # Build only
#   COMPS="binutils gcc" bash releng/ci-release.sh          # Build selected components
set -uo pipefail
SRCDIR="${SRCDIR:-/workspace/devtoolset-16}"
OUT="${OUT:-/out}"
BUILD_ROOT="${BUILD_ROOT:-/build}"
RELEASE_TAG="${RELEASE_TAG:-16.2.1}"
DO_RELEASE="${RELEASE:-1}"

source "$SRCDIR/releng/ci-common.sh"
set +e

ALL_ORDER="automake dwz ltrace strace make annobin elfutils binutils valgrind dyninst systemtap gdb gcc meta"
ORDER="${COMPS:-$ALL_ORDER}"

log "===== devtoolset-16 release build (tag=$RELEASE_TAG) ====="
setup_repos; install_toolchain; setup_dirs
ensure_automake || log "ensure_automake fallback to system automake"
log "toolchain: $(scl enable devtoolset-14 'gcc -v' 2>&1 | tail -1)"
log "components: $ORDER"

declare -A RC
for COMP in $ORDER; do
  log "########## $COMP ##########"
  if [ "$COMP" = "automake" ]; then
    RC[$COMP]=0
    continue
  fi
  SPEC=$(prepare_spec "$COMP") || { echo "!! prepare_spec failed: $COMP"; RC[$COMP]=1; continue; }
  case "$COMP" in
    gcc) bash "$SRCDIR/releng/fetch-gcc-srcs.sh" "$BUILD_ROOT/SOURCES" 2>&1 | tail -30 ;;
    *)   bash "$SRCDIR/releng/fetch-srcs.sh" "$COMP" "$BUILD_ROOT/SOURCES" 2>&1 | tail -20 ;;
  esac
  install_built_prereqs "$COMP"
  ( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] $COMP building..."; done ) &
  HB=$!
  scl enable devtoolset-14 "rpmbuild -ba --nodeps --nocheck '$SPEC'" 2>&1 | tee "$OUT/logs/$COMP.log"
  rc=${PIPESTATUS[0]}
  kill "$HB" 2>/dev/null || true
  RC[$COMP]=$rc
  echo ">>> $COMP rc=$rc"
  if [ "$rc" != 0 ]; then
    echo "--- $COMP failure summary ---"
    grep -iE "error:|Error [0-9]|Bad exit status|No targets|File not found by glob|not found" \
      "$OUT/logs/$COMP.log" | tail -15
  fi
done

log "===== SUMMARY ====="
FAILED=""
for c in $ORDER; do
  printf '%-12s rc=%s\n' "$c" "${RC[$c]:-?}"
  [ "${RC[$c]:-1}" = 0 ] || FAILED="$FAILED $c"
done

log "===== ARTIFACTS ====="
mapfile -t RPMS < <(find "$OUT/rpms" -name '*.rpm' | sort)
mapfile -t SRPMS < <(find "$OUT/srpms" -name '*.rpm' | sort)
printf 'binary rpm: %s  src.rpm: %s\n' "${#RPMS[@]}" "${#SRPMS[@]}"
printf '%s\n' "${RPMS[@]}" "${SRPMS[@]}"

[ ${#RPMS[@]} -gt 0 ] || { log "!! no rpm artifacts produced"; exit 1; }

if [ "$DO_RELEASE" = 1 ]; then
  log "===== BUNDLE RELEASE $RELEASE_TAG ====="
  BUNDLE="$OUT/devtoolset-16-${RELEASE_TAG}-rpms.tar.gz"
  tar czf "$BUNDLE" -C "$OUT" rpms srpms
  ( cd "$OUT" && sha256sum "$(basename "$BUNDLE")" > sha256sums.txt )
  log "release bundle created: $BUNDLE"
fi

[ -z "$FAILED" ] || { log "!! failed components:$FAILED"; exit 1; }
log "===== DONE ====="
