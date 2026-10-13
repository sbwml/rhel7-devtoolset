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

[devtoolset-12]
name=devtoolset-12
baseurl=https://download.copr.fedorainfracloud.org/results/mlampe/devtoolset-12/epel-7-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=0
repo_gpgcheck=0
enabled=1

[epel-archive]
name=EPEL 7 (archive)
baseurl=https://archives.fedoraproject.org/pub/archive/epel/7/\$basearch/
gpgcheck=0
enabled=1
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
  yum -y install devtoolset-12-gcc devtoolset-12-gcc-c++ devtoolset-12-make \
    devtoolset-12-binutils devtoolset-12-runtime >/dev/null 2>&1 || true

  yum -y install binutils-devel elfutils-devel elfutils-libelf-devel \
    libzstd-devel libmicrohttpd-devel libarchive-devel json-c-devel \
    libmicrohttpd libarchive \
    boost-devel tbb-devel cmake libtirpc-devel libacl-devel bluez-libs-devel \
    libselinux-devel nss-devel avahi-devel sqlite-devel rpm-devel \
    nspr-devel libcurl-devel gettext-devel procps-ng time perl-interpreter \
    gdb-headless pkgconfig libstdc++-static glibc-static zlib-static \
    bzip2-devel guile-devel texinfo help2man iso-codes \
    wget curl tar xz bzip2 cpio sudo which file help2man autoconf automake \
    libuuid-devel popt-devel glib2-devel \
    systemtap-sdt-devel >/dev/null 2>&1 || true
  yum -y install clang llvm llvm-devel compiler-rt >/dev/null 2>&1 || true
  yum -y install dyninst-devel dyninst >/dev/null 2>&1 || true
  echo ">>> Installing elfutils/annobin dependencies"
  yum -y install libmicrohttpd-devel libarchive-devel json-c-devel \
    sqlite-devel libcurl-devel ima-evm-utils-devel openssl-devel \
    gcc-plugin-devel python3-devel python2-devel python2-setuptools 2>&1 | tail -25 || true
  if rpm -q json-c-devel >/dev/null 2>&1; then
    echo ">>> json-c-devel OK: $(pkg-config --modversion json-c 2>/dev/null || echo 'no .pc')"
  else
    echo "!! json-c-devel not installed: stap-jupyter may not build"
  fi
  echo ">>> gcc plugin dir: $(gcc --print-file-name=plugin)"
  ls "$(gcc --print-file-name=plugin)"/bversion.h 2>&1 || true
  install_epel_extras
}

install_epel_extras() {
  echo ">>> Checking build-time prerequisites"
  if ! rpm -q xxhash-devel >/dev/null 2>&1; then
    yum -y --nogpgcheck --enablerepo=epel-archive install xxhash-devel 2>&1 | tail -5 || true
  fi
  if ! rpm -q cmake3 >/dev/null 2>&1; then
    yum -y --nogpgcheck --enablerepo=epel-archive install cmake3 cmake3-data 2>&1 | tail -5 || true
  fi
  if ! rpm -q libbabeltrace-devel >/dev/null 2>&1; then
    yum -y --nogpgcheck --enablerepo=epel-archive install libbabeltrace libbabeltrace-devel 2>&1 | tail -5 || true
  fi
  if ! rpm -q boost183-devel >/dev/null 2>&1 && ! rpm -q boost169-devel >/dev/null 2>&1; then
    yum -y --nogpgcheck --enablerepo=epel-archive install boost169-devel 2>&1 | tail -5 || true
  fi
  setup_boost_env
  if [ -x /usr/bin/cmake3 ]; then
    ln -sf /usr/bin/cmake3 /usr/local/bin/cmake
  fi
  install_tbb_shim
  rpm -q xxhash-devel >/dev/null 2>&1 || echo "!! xxhash-devel not installed"
  command -v cmake >/dev/null && cmake --version | head -1
}

setup_boost_env() {
  local inc=/usr/include/boost183
  if [ ! -d "$inc" ]; then
    inc=/usr/include/boost169
  fi
  if [ -d "$inc" ]; then
    ln -sfn "$inc" "/usr/local/include/$(basename "$inc")"
    for so in /usr/lib64/libboost_*.so.*.*; do
      [ -e "$so" ] || continue
      b=$(basename "$so")
      stem=${b%%.so.*}
      case "$stem" in *-mt) continue;; esac
      ln -sfn "$so" "/usr/lib64/${stem}.so" 2>/dev/null || true
      ln -sfn "$so" "/usr/lib64/${stem}-mt.so" 2>/dev/null || true
    done
    for l in /usr/lib64/boost183/libboost_*.so; do
      [ -e "$l" ] || continue
      b=$(basename "$l")
      ln -sfn "$l" "/usr/lib64/$b" 2>/dev/null || true
    done
    for a in /usr/lib64/libboost_*-mt-*.a; do
      [ -e "$a" ] || continue
      b=$(basename "$a"); ln -sfn "$a" "/usr/lib64/${b/-mt/}" 2>/dev/null || true
    done
    export CPLUS_INCLUDE_PATH="$inc${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
    export C_INCLUDE_PATH="$inc${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}"
  fi
  install_boost_header_overlay
  install_boost_cmake_shim
}

install_boost_header_overlay() {
  local inc=/usr/include/boost183/boost
  [ -d "$inc" ] || inc=/usr/include/boost169/boost
  [ -d "$inc" ] || { echo "!! boost headers not found, skip overlay"; return 0; }
  if [ -f "$inc/variant2/variant.hpp" ]; then
    echo ">>> boost header overlay ready"
    return 0
  fi
  local ver=boost-1.83.0 base=https://codeload.github.com/boostorg work=/tmp/boost-overlay
  mkdir -p "$work"
  for lib in variant2 mp11 assert config; do
    local tgz="$work/$lib.tar.gz"
    [ -s "$tgz" ] || curl -fL --retry 3 --retry-delay 3 --connect-timeout 30 --max-time 600 \
      -o "$tgz" "$base/$lib/tar.gz/refs/tags/$ver" 2>&1 | tail -1
    if [ -s "$tgz" ]; then
      local d="$work/$lib"
      rm -rf "$d"; mkdir -p "$d"
      tar xzf "$tgz" -C "$d" --strip-components=1
      if [ -d "$d/include/boost" ]; then
        cp -a "$d/include/boost/." "$inc/" 2>/dev/null || true
      fi
    else
      echo "!! Fetching $lib failed"
    fi
  done
  if [ -f "$inc/variant2/variant.hpp" ]; then
    echo ">>> boost header overlay OK: $(ls "$inc/variant2/")"
  else
    echo "!! boost header overlay failed"
  fi
}

install_boost_cmake_shim() {
  local inc=/usr/include/boost183 libdir=/usr/lib64 ver=1.83.0 maj=1 min=83 bver=108300
  if [ ! -d "$inc" ]; then
    inc=/usr/include/boost169
    ver=1.69.0; maj=1; min=69; bver=106900
  fi
  [ -d "$inc" ] || { echo "!! boost headers not found, skip Boost shim"; return 0; }
  local dest=/usr/local/lib64/cmake/Boost
  mkdir -p "$dest"
  cat > "$dest/BoostConfig.cmake" <<BOOSTEOF
set(Boost_NO_WARN_NEW_VERSIONS ON)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)
set(Boost_ROOT "/usr")
set(Boost_INCLUDE_DIR "$inc")
set(Boost_INCLUDE_DIRS "$inc")
set(Boost_LIBRARY_DIR "/usr/lib64")

set(Boost_VERSION $ver)
set(Boost_VERSION_STRING "$ver")
set(Boost_MAJOR_VERSION $maj)
set(Boost_MINOR_VERSION $min)
set(Boost_SUBMINOR_VERSION 0)
set(BOOST_VERSION $bver)
set(Boost_FOUND TRUE)

foreach(_comp atomic chrono date_time filesystem thread timer)
  find_library(Boost_\${_comp}_LIBRARY_REAL
    NAMES boost_\${_comp}-mt boost_\${_comp} boost_\${_comp}-mt-$ver boost_\${_comp}-$ver
    PATHS /usr/lib64 /usr/lib /usr/local/lib64 /usr/lib64/boost183
    NO_DEFAULT_PATH)
  if(NOT Boost_\${_comp}_LIBRARY_REAL)
    message(FATAL_ERROR "Boost shim: boost_\${_comp} library not found")
  endif()
  if(NOT TARGET Boost::\${_comp})
    add_library(Boost::\${_comp} UNKNOWN IMPORTED)
    set_target_properties(Boost::\${_comp} PROPERTIES
      IMPORTED_LOCATION "\${Boost_\${_comp}_LIBRARY_REAL}"
      INTERFACE_INCLUDE_DIRECTORIES "\${Boost_INCLUDE_DIRS}")
  endif()
  list(APPEND Boost_LIBRARIES Boost::\${_comp})
endforeach()

if(NOT TARGET Boost::headers)
  add_library(Boost::headers INTERFACE IMPORTED)
  set_target_properties(Boost::headers PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "\${Boost_INCLUDE_DIRS}")
endif()

if(TARGET Boost::headers AND Boost_LIBRARIES)
  set_target_properties(Boost::headers PROPERTIES
    INTERFACE_LINK_LIBRARIES "\${Boost_LIBRARIES}")
endif()

message(STATUS "Boost(shim) \${Boost_VERSION} include=\${Boost_INCLUDE_DIRS}")
BOOSTEOF
  cat > "$dest/BoostConfigVersion.cmake" <<BOOSTVEREOF
set(PACKAGE_VERSION "$ver")
if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
  set(PACKAGE_VERSION_COMPATIBLE FALSE)
else()
  set(PACKAGE_VERSION_COMPATIBLE TRUE)
  if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
  endif()
endif()
BOOSTVEREOF

  for l in /usr/lib64/libboost_*-mt-1.69.so /usr/lib64/libboost_*-1.83.so* /usr/lib64/boost183/libboost_*.so; do
    [ -e "$l" ] || continue
    b=$(basename "$l")
    stem=${b%%.so.*}
    ln -sfn "$l" "/usr/lib64/${stem}.so" 2>/dev/null || true
  done
  echo ">>> Boost cmake shim: $dest/BoostConfig.cmake (boost $ver)"
}

install_tbb_shim() {
  local dest=/usr/local/lib64/cmake/TBB prefix=/opt/tbb2019
  local tgz=/tmp/tbb2019.lin.tgz
  local url="https://github.com/uxlfoundation/oneTBB/releases/download/2019_U9/tbb2019_20191006oss_lin.tgz"

  if [ ! -d "$prefix/include/tbb" ]; then
    echo ">>> Fetching TBB 2019_U9"
    curl -fL --retry 3 --retry-delay 5 --connect-timeout 30 --max-time 900 \
         -o "$tgz" "$url" 2>&1 | tail -2
    if [ -s "$tgz" ]; then
      rm -rf "$prefix"; mkdir -p "$prefix"
      tar xzf "$tgz" -C "$prefix" --strip-components=1
    fi
  fi

  local src="$prefix"
  [ -d "$src/include/tbb" ] || { echo "!! TBB 2019_U9 not found"; return 0; }

  mkdir -p /usr/local/include
  cp -a "$src/include/tbb" /usr/local/include/
  if [ -d "$src/lib/intel64/gcc4.8" ]; then
    cp -a "$src"/lib/intel64/gcc4.8/libtbb*.so*   /usr/local/lib64/ 2>/dev/null || true
    cp -a "$src"/lib/intel64/gcc4.8/libtbb*.so    /usr/local/lib64/ 2>/dev/null || true
  fi
  echo "/usr/local/lib64" > /etc/ld.so.conf.d/tbb2019.conf
  ldconfig 2>/dev/null || true

  mkdir -p "$dest"
  cat > "$dest/TBBConfig.cmake" <<'TBBEOF'
set(TBB_VERSION "2019.9")
set(TBB_FOUND TRUE)
set(TBB_INCLUDE_DIRS "/usr/local/include")
set(TBB_LIBRARY_DIRS "/usr/local/lib64")
set(TBB_tbb_LIBRARY "/usr/local/lib64/libtbb.so")
set(TBB_tbbmalloc_LIBRARY "/usr/local/lib64/libtbbmalloc.so")
set(TBB_tbbmalloc_proxy_LIBRARY "/usr/local/lib64/libtbbmalloc_proxy.so")

foreach(_c tbb tbbmalloc tbbmalloc_proxy)
  if(NOT TARGET TBB::${_c})
    add_library(TBB::${_c} UNKNOWN IMPORTED)
    set_target_properties(TBB::${_c} PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "/usr/local/include")
    if(EXISTS "${TBB_${_c}_LIBRARY}")
      set_target_properties(TBB::${_c} PROPERTIES
        IMPORTED_LOCATION "${TBB_${_c}_LIBRARY}")
    endif()
  endif()
endforeach()

set(TBB_LIBRARIES TBB::tbb TBB::tbbmalloc TBB::tbbmalloc_proxy)
message(STATUS "TBB(shim) ${TBB_VERSION} include=${TBB_INCLUDE_DIRS}")
TBBEOF

  cat > "$dest/TBBConfigVersion.cmake" <<'TBBVEREOF'
set(PACKAGE_VERSION "2019.9")
set(PACKAGE_VERSION_COMPATIBLE TRUE)
if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
  set(PACKAGE_VERSION_EXACT TRUE)
endif()
TBBVEREOF
  echo ">>> TBB 2019_U9 ready: $(ls /usr/local/lib64/libtbb.so* 2>/dev/null | head -1)"
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
%with_crash 0
%with_emacsvim 0
%with_python2_probes 0
%with_java 0
%with_dyninst 0
%with_debuginfod 0
%with_bpf 0
%with_virthost 0
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

ensure_autoconf() {
  local have
  have=$(autoconf --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  case "$have" in
    2.7[1-9]|2.[8-9]*) log "autoconf already ${have}, skip"; return 0;;
  esac
  log "autoconf: ${have:-none} < 2.71 -> building devtoolset-16-autoconf 2.71"
  local spec
  spec=$(prepare_spec autoconf) || { log "!! autoconf spec preparation failed"; return 1; }
  bash "$SRCDIR/releng/fetch-srcs.sh" autoconf "$BUILD_ROOT/SOURCES" 2>&1 | tail -20
  ( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] autoconf building..."; done ) &
  local hb=$!
  scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$spec'" 2>&1 | tee "$OUT/logs/autoconf.log"
  local rc=${PIPESTATUS[0]}
  kill "$hb" 2>/dev/null || true
  [ "$rc" = 0 ] || { log "!! autoconf build failed rc=$rc"; return "$rc"; }
  local found
  found=$(find "$OUT/rpms" -name '*autoconf*.noarch.rpm' -print -quit)
  [ -n "$found" ] || { log "!! autoconf rpm not found"; return 1; }
  find "$OUT/rpms" -name '*autoconf*.noarch.rpm' -exec rpm -Uvh --nodeps --force {} + 2>&1 | tail -5
  if [ -x /opt/rh/devtoolset-16/root/usr/bin/autoconf ]; then
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/autoconf /usr/bin/autoconf
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/autoheader /usr/bin/autoheader
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/autom4te /usr/bin/autom4te
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/autoreconf /usr/bin/autoreconf
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/autoscan /usr/bin/autoscan
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/autoupdate /usr/bin/autoupdate
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/ifnames /usr/bin/ifnames
  fi
  log "autoconf now: $(autoconf --version 2>/dev/null | head -1)"
  autoconf --version 2>/dev/null | head -1 | grep -qE '2\.7[1-9]|2\.[8-9]'
}

ensure_automake() {
  local have
  have=$(automake --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  case "$have" in
    1.1[5-9]|1.[2-9]) log "automake already ${have}, skip"; return 0;;
  esac
  log "automake: ${have:-none} < 1.16 -> building devtoolset-16-automake 1.16.1"
  local spec
  spec=$(prepare_spec automake) || { log "!! automake spec preparation failed"; return 1; }
  bash "$SRCDIR/releng/fetch-srcs.sh" automake "$BUILD_ROOT/SOURCES" 2>&1 | tail -20
  ( while :; do sleep 60; echo "[heartbeat $(date '+%H:%M:%S')] automake building..."; done ) &
  local hb=$!
  scl enable devtoolset-12 "rpmbuild -ba --nodeps --nocheck '$spec'" 2>&1 | tee "$OUT/logs/automake.log"
  local rc=${PIPESTATUS[0]}
  kill "$hb" 2>/dev/null || true
  [ "$rc" = 0 ] || { log "!! automake build failed rc=$rc"; return "$rc"; }
  local found
  found=$(find "$OUT/rpms" -name '*automake*.noarch.rpm' -print -quit)
  [ -n "$found" ] || { log "!! automake rpm not found"; return 1; }
  find "$OUT/rpms" -name '*automake*.noarch.rpm' -exec rpm -Uvh --nodeps --force {} + 2>&1 | tail -5
  if [ -x /opt/rh/devtoolset-16/root/usr/bin/automake ]; then
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/automake /usr/bin/automake
    ln -sf /opt/rh/devtoolset-16/root/usr/bin/aclocal /usr/bin/aclocal
  fi
  log "automake now: $(automake --version 2>/dev/null | head -1)"
  automake --version 2>/dev/null | head -1 | grep -qE '1\.1[6-9]|1\.[2-9]'
}

prepare_spec() {
  local comp="$1"
  if [ -d "$SRCDIR/specs/$comp-el7" ]; then
    local sdir="$SRCDIR/specs/$comp-el7"
    find "$sdir" -maxdepth 1 -type f \
      ! -name '*.spec' ! -name 'sources' -exec cp -f {} "$BUILD_ROOT/SOURCES/" \;
    cp -f "$sdir"/sources "$BUILD_ROOT/SOURCES/sources-$comp" 2>/dev/null || true
    local spec out
    spec=$(find "$sdir" -maxdepth 1 -name '*.spec' | head -1)
    out="$BUILD_ROOT/SPECS/$(basename "$spec")"
    cp -f "$spec" "$out"
    el7_spec_compat "$out"
    echo "$out"
    return 0
  fi
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

  sed -i 's/%scl_package ltrace/%scl_package make/' "$out" 2>/dev/null || true

  el7_spec_compat "$out"
  echo "$out"
}

scl_wire_generic() {
  local out="$1" comp="$2"
  case "$comp" in
    xxhash|babeltrace|boost|boost183) return 0;;
  esac
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
  sed -i 's/^%global with_hard_gcc_version_requirement 1/%global with_hard_gcc_version_requirement 0/' "$out"
  sed -i -E 's|^echo "Requires: \\(.*\\)"|true # rich dep removed for rpm 4.11|' "$out"

  case "$(basename "$out")" in
    strace.spec) sed -i -E 's/^%global _hardened_build 1/%global _hardened_build 0/' "$out"
                 sed -i -E 's/ -Werror(=array-bounds)?//g' "$out";;
  esac
  sed -i -E '/^Source3: standards\.info\.gz$/d' "$out"
  sed -i -E '/standards\.info\.gz/d' "$out"
  sed -i -E '/%\{_infodir\}\/standards\.info/d' "$out"

  case "$(basename "$out")" in
    elfutils.spec)
      sed -i -E 's/^%autosetup( .*)?$/&\n%bcond_with check/' "$out"
      ;;
    ltrace.spec)
      sed -i -E 's/^%setup( .*)?$/&\n%bcond_without autoreconf/' "$out"
      sed -i -E 's|^autoreconf -i\s*$|%{?with_autoreconf:autoreconf -i -f}|' "$out"
      ;;
  esac
  if ! automake --version 2>/dev/null | head -1 | grep -qE '1\.(1[5-9]|[2-9])'; then
    sed -i -E 's/^autoreconf .*/# autoreconf skipped (C7 automake too old)/' "$out"
  fi

  sed -i \
    -e 's/^%bcond_without debuginfod$/%bcond_with debuginfod/' \
    -e 's/^%bcond_without testsuite$/%bcond_with testsuite/' \
    -e 's/^%bcond_without docs$/%bcond_with docs/' \
    -e 's/^%bcond_without gprofng$/%bcond_with gprofng/' \
    -e 's/^%bcond_without crossbuilds$/%bcond_with crossbuilds/' \
    -e 's/^%bcond_without clang$/%bcond_with clang/' \
    -e 's/^%bcond_without gold$/%bcond_with gold/' \
    -e 's/^%bcond_without systemzlib$/%bcond_with systemzlib/' \
    -e 's/^%bcond_without xxhash$/%bcond_with xxhash/' \
    -e 's/^%bcond_without zstd$/%bcond_with zstd/' \
    -e 's/^%bcond_without clangplugin$/%bcond_with clangplugin/' \
    -e 's/^%bcond_without llvmplugin$/%bcond_with llvmplugin/' \
    "$out"

  BOOT_GCC=/opt/rh/devtoolset-12/root/usr/bin/gcc
  BOOT_GXX=/opt/rh/devtoolset-12/root/usr/bin/g++

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
    babeltrace)
      if ! rpm -q libuuid-devel popt-devel glib2-devel >/dev/null 2>&1; then
        log "install build requirements for babeltrace (libuuid-devel, popt-devel, glib2-devel)"
        yum -y install libuuid-devel popt-devel glib2-devel 2>&1 | tail -5 || true
      fi
      ;;
    dwz)
      local rpms
      rpms=$(find "$OUT/rpms" -name 'xxhash*.rpm' 2>/dev/null | sort)
      if [ -n "$rpms" ]; then
        log "install prereq xxhash -> build environment"
        rpm -Uvh --nodeps --force $rpms 2>&1 | tail -5
      fi
      ;;
    binutils)
      local rpms
      rpms=$(find "$OUT/rpms" -name 'xxhash*.rpm' 2>/dev/null | sort)
      if [ -n "$rpms" ]; then
        log "install prereq xxhash -> build environment"
        rpm -Uvh --nodeps --force $rpms 2>&1 | tail -5
      fi
      ;;
    gdb)
      local rpms
      rpms=$(find "$OUT/rpms" \( -name '*babeltrace*.rpm' -o -name 'xxhash*.rpm' \) 2>/dev/null | sort)
      if [ -n "$rpms" ]; then
        log "install prereq babeltrace/xxhash -> build environment"
        rpm -Uvh --nodeps --force $rpms 2>&1 | tail -5
      fi
      ;;
    dyninst)
      local rpms
      rpms=$(find "$OUT/rpms" -name 'boost183*.rpm' 2>/dev/null | sort)
      if [ -n "$rpms" ]; then
        log "install prereq boost183 -> build environment"
        rpm -Uvh --nodeps --force $rpms 2>&1 | tail -5
        setup_boost_env
      fi
      local elf_rpms
      elf_rpms=$(find "$OUT/rpms" -name 'devtoolset-16-elfutils*.rpm' \
             ! -name '*debuginfod*' ! -name '*default-yama*' 2>/dev/null | sort)
      if [ -n "$elf_rpms" ]; then
        log "install prereq elfutils -> build environment"
        # shellcheck disable=SC2086
        rpm -Uvh --nodeps --force $elf_rpms 2>&1 | tail -5
        local pc="/opt/rh/devtoolset-16/root/usr/lib64/pkgconfig"
        export PKG_CONFIG_PATH="$pc:${PKG_CONFIG_PATH:-}"
        export CMAKE_PREFIX_PATH="/opt/rh/devtoolset-16/root/usr:${CMAKE_PREFIX_PATH:-}"
        log "pkg-config libelf: $(pkg-config --modversion libelf 2>/dev/null || echo 'n/a')"
      else
        log "!! no built elfutils rpm available for dyninst"
      fi
      ;;
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
