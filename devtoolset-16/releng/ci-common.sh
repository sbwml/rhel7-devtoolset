#!/bin/bash
# devtoolset-16 build environment (sourced inside centos:7 container)
set -e

MIRROR="${MIRROR:-http://mirrorlist.cooluc.com}"
BUILD_ROOT="${BUILD_ROOT:-/build}"
OUT="${OUT:-/out}"
SRCDIR="${SRCDIR:-/workspace/devtoolset-16}"

log() { echo -e "\n\033[1;36m>>> $*\033[0m"; }

setup_repos() {
  mkdir -p /etc/yum/vars && echo "7" > /etc/yum/vars/releasever
  mkdir -p /etc/yum.repos.d
  rm -f /etc/yum.repos.d/CentOS-*.repo
  cat > /etc/yum.repos.d/cooluc.repo <<REPO
[base]
name=CentOS-7 - Base
mirrorlist=${MIRROR}/?release=7&arch=\$basearch&repo=os
gpgcheck=0
enabled=1

[updates]
name=CentOS-7 - Updates
mirrorlist=${MIRROR}/?release=7&arch=\$basearch&repo=updates
gpgcheck=0
enabled=1

[extras]
name=CentOS-7 - Extras
mirrorlist=${MIRROR}/?release=7&arch=\$basearch&repo=extras
gpgcheck=0
enabled=1

[epel]
name=EPEL 7
baseurl=https://mirrors.aliyun.com/epel/7/\$basearch/
        https://archives.fedoraproject.org/pub/archive/epel/7/\$basearch/
failovermethod=priority
gpgcheck=0
enabled=1

[devtoolset-14]
name=Red Hat Developer Toolset 14 CentOS 7 - \$basearch
baseurl=https://el7.cooluc.com/7/Packages
failovermethod=priority
enabled=1
gpgcheck=0
REPO
}

install_toolchain() {
  yum -y install yum-utils rpm-build createrepo rpm-sign gnupg2 sudo >/dev/null 2>&1 || true
  yum -y install make wget curl tar xz bzip2 gzip zip unzip cpio which \
    patch diffutils findutils file sed gawk grep glibc-devel glibc-static \
    bison flex m4 gettext texinfo autoconf automake libtool pkgconfig \
    python3 python2 perl perl-devel perl-generators scl-utils scl-utils-build \
    policycoreutils jansson-devel zlib-devel sharutils bc dejagnu libstdc++-static \
    ncurses-devel readline-devel expat-devel libstdc++-devel gmp-devel mpfr-devel \
    libmpc-devel isl-devel xz-devel guile-devel libtool-ltdl-devel help2man iso-codes >/dev/null 2>&1 || true

  log "Installing devtoolset-14 toolchain..."
  yum -y install devtoolset-14 2>&1 | tail -25 || true
}

setup_dirs() {
  mkdir -p "$BUILD_ROOT"/{SOURCES,SPECS,BUILD,BUILDROOT,RPMS} "$OUT"/{rpms,srpms,logs}
  cat > ~/.rpmmacros <<MACRO
%_topdir $BUILD_ROOT
%_sourcedir $BUILD_ROOT/SOURCES
%_specdir $BUILD_ROOT/SPECS
%_builddir $BUILD_ROOT/BUILD
%_buildrootdir $BUILD_ROOT/BUILDROOT
%_rpmdir $OUT/rpms
%_srcrpmdir $OUT/srpms
%_scl_prefix /opt/rh
%scl devtoolset-16
%dist .el7
%el7 1
%rhel 7
%devtoolset_16 1
%devtoolset_14 1
%_missing_doc_files_terminate_build 0
%_unpackaged_files_terminate_build 0
%__brp_mangle_shebangs %{nil}
%__brp_check_rpaths %{nil}
%__brp_python_bytecompile %{nil}
%__debug_install_post %{nil}
%__os_install_post %{nil}
%debug_package %{nil}
%_enable_debug_packages 0
%_smp_mflags -j%{_smp_ncpus}
%_smp_ncpus 4
%bcond_with() %{expand:%{lua:rpm.define("without_"..rpm.expand("%*").." 1")}}
%bcond_without() %{expand:%{lua:rpm.define("with_"..rpm.expand("%*").." 1")}}
%set_build_flags %{expand:RPM_SOURCE_DIR="%{_sourcedir}" ; export RPM_SOURCE_DIR ; RPM_BUILD_DIR="%{_builddir}" ; export RPM_BUILD_DIR ; RPM_OPT_FLAGS="%{optflags}" ; export RPM_OPT_FLAGS ; RPM_LD_FLAGS="%{?__global_ldflags}" ; export RPM_LD_FLAGS ; RPM_ARCH="%{_target_cpu}" ; export RPM_ARCH ; RPM_OS="linux" ; export RPM_OS ; RPM_DOC_DIR="%{_docdir}" ; export RPM_DOC_DIR ;}
%build_cflags %{optflags}
%build_cxxflags %{optflags}
%build_fflags %{optflags}
%build_ldflags %{?__global_ldflags}
MACRO
  cp -f "$SRCDIR/releng/macros.el7-compat" /etc/rpm/macros.devtoolset-16-compat 2>/dev/null || true
}

prepare_spec() {
  local comp="$1"
  if [ -d "$SRCDIR/specs/$comp-el10" ]; then
    local sdir="$SRCDIR/specs/$comp-el10"
    find "$sdir" -maxdepth 1 -type f \
      ! -name '*.spec' ! -name 'sources' -exec cp -f {} "$BUILD_ROOT/SOURCES/" \;
    cp -f "$sdir"/sources "$BUILD_ROOT/SOURCES/sources-$comp" 2>/dev/null || true
    local spec out
    spec=$(find "$sdir" -maxdepth 1 -name '*.spec' | head -1)
    out="$BUILD_ROOT/SPECS/$(basename "$spec")"
    cp -f "$spec" "$out"
    scl_wire_generic "$out" "$comp"
    el7_spec_compat "$out"
    echo "$out"
    return 0
  fi

  local sdir="$SRCDIR/specs/$comp"
  [ -d "$sdir" ] || { echo "no spec dir: $sdir"; return 1; }

  cp -f "$sdir"/*.patch "$BUILD_ROOT/SOURCES/" 2>/dev/null || true
  cp -f "$sdir"/*.sh "$BUILD_ROOT/SOURCES/" 2>/dev/null || true
  cp -f "$sdir"/sources "$BUILD_ROOT/SOURCES/sources-$comp" 2>/dev/null || true
  find "$sdir" -maxdepth 1 -type f \( -name '*.spec' -o -name 'README*' -o -name '*.in' -o -name '*.gts' \) -exec cp -f {} "$BUILD_ROOT/SOURCES/" \;

  local spec out
  spec=$(find "$sdir" -maxdepth 1 -name '*.spec' | head -1)
  out="$BUILD_ROOT/SPECS/$(basename "$spec")"

  sed -e 's/gcc-toolset-16/devtoolset-16/g' \
      -e 's/gcc_toolset_16/devtoolset_16/g' \
      -e 's/GCC Toolset 16/Developer Toolset 16/g' \
      "$spec" > "$out"

  el7_spec_compat "$out"
  echo "$out"
}

scl_wire_generic() {
  local out="$1" comp="$2"
  [ -f "$SRCDIR/releng/scl-wire.py" ] || return 0
  python3 "$SRCDIR/releng/scl-wire.py" "$out" "$comp" || true
}

el7_spec_compat() {
  local out="$1"
  if [ -f "$SRCDIR/releng/el7-compat.py" ]; then
    python3 "$SRCDIR/releng/el7-compat.py" "$out" || true
  fi
  sed -i -E '/^%dnl( |$)/d' "$out"
  sed -i -E 's/^(Recommends|Suggests|Supplements|Enhances):/##### &/' "$out"
  sed -i -E 's/^(Requires|BuildRequires|Conflicts|Provides): *\(.*\)$/##### &/' "$out"
  sed -i -E 's/^(Requires|BuildRequires|Conflicts|Provides): *\(.*with.*\)$/##### &/' "$out"
  sed -i -E 's/^Requires\(/##### Requires(/' "$out"

  sed -i \
    -e 's/^%bcond_without debuginfod$/%bcond_with debuginfod/' \
    -e 's/^%bcond_without testsuite$/%bcond_with testsuite/' \
    -e 's/^%bcond_without docs$/%bcond_with docs/' \
    -e 's/^%bcond_without gprofng$/%bcond_with gprofng/' \
    -e 's/^%bcond_without crossbuilds$/%bcond_with crossbuilds/' \
    -e 's/^%bcond_without clang$/%bcond_with clang/' \
    -e 's/^%bcond_without gold$/%bcond_with gold/' \
    -e 's/^%bcond_without systemzlib$/%bcond_with systemzlib/' \
    "$out"

  BOOT_GCC=/opt/rh/devtoolset-14/root/usr/bin/gcc
  BOOT_GXX=/opt/rh/devtoolset-14/root/usr/bin/g++

  python3 - "$out" "$BOOT_GCC" "$BOOT_GXX" <<'PYEOF' || true
import sys, re
spec, gcc, gxx = sys.argv[1:4]
s = open(spec, encoding='utf-8', errors='replace').read()
s = re.sub(r'%define gcc_for_binutils .*', '%define gcc_for_binutils ' + gcc, s)
s = re.sub(r'%define gxx_for_binutils .*', '%define gxx_for_binutils ' + gxx, s)
open(spec, 'w', encoding='utf-8').write(s)
PYEOF
}

install_built_prereqs() {
  local comp="$1"
  case "$comp" in
    gcc)
      local rpms
      rpms=$(find "$OUT/rpms" -name 'devtoolset-16-binutils*.rpm' 2>/dev/null | sort)
      if [ -n "$rpms" ]; then
        log "install prereq binutils -> build environment"
        # shellcheck disable=SC2086
        rpm -Uvh --nodeps --force $rpms 2>&1 | tail -5
      else
        log "!! warning: no built devtoolset-16-binutils rpm found"
      fi
      ;;
  esac
}
