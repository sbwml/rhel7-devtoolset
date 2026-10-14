# devtoolset-16 / cmake 3.31.8
# Baseline: cmake-3.31.8-1.el10.src.rpm (Rocky Linux 10 AppStream)
# Disable debuginfo package generation
%global debug_package %{nil}
%global __debug_install_post %{nil}
%undefine _enable_debug_packages

%{?scl_package:%global scl devtoolset-16}
%global scl_name devtoolset-16
%global scl_prefix devtoolset-16-
%global pkg_name cmake
BuildRequires: scl-utils-build
%{?scl:%scl_package cmake}

# Do we add appdata-files?
%bcond_with appdata

# Build with bootstrap / bundled libraries
%bcond_without bootstrap

# Build with Emacs support
%bcond_with emacs

# Run git tests
%bcond_with git_test

# Disable qt gui build
%bcond_with gui

# Use ncurses for colorful output
%bcond_without ncurses

# Python version / RPM dependency generators
%bcond_with python3
%bcond_with rpm
%bcond_with sphinx

%bcond_without bundled_cppdap
%bcond_without bundled_jsoncpp
%bcond_without bundled_rhash

# Run tests
%bcond_with test
%bcond_with X11_test

%if 0%{?rhel} >= 8
%global build_cflags   %(echo '%{build_cflags}'   | sed -e 's!-ffat-lto-objects!-fno-fat-lto-objects!g')
%global build_cxxflags %(echo '%{build_cxxflags}' | sed -e 's!-ffat-lto-objects!-fno-fat-lto-objects!g')
%global build_fflags   %(echo '%{build_fflags}' | sed -e 's!-ffat-lto-objects!-fno-fat-lto-objects!g')
%global build_fcflags  %(echo '%{build_fflags}' | sed -e 's!-ffat-lto-objects!-fno-fat-lto-objects!g')
%endif

# Place rpm-macros into proper location
%global rpm_macros_dir %(d=%{_rpmconfigdir}/macros.d; [ -d $d ] || d=%{_sysconfdir}/rpm; echo $d)

# Setup _pkgdocdir if not defined already
%{!?_pkgdocdir:%global _pkgdocdir %{_docdir}/%{name}-%{version}}

# Setup _vpath_builddir if not defined already
%{!?_vpath_builddir:%global _vpath_builddir %{_target_platform}}

# Setup vimfiles_root if not defined already
%{!?vimfiles_root:%global vimfiles_root %{_datadir}/vim/vimfiles}

# Setup bash_completionsdir if not defined already
%global bash_completionsdir %{_datadir}/bash-completion/completions

%global major_version 3
%global minor_version 31
%global patch_version 8

%global baserelease 1
%global pkg_version %{major_version}.%{minor_version}.%{patch_version}
%global tar_version %{major_version}.%{minor_version}.%{patch_version}
%global orig_name cmake

Name:           %{?scl_prefix}%{orig_name}
Version:        %{pkg_version}
Release:        %{baserelease}%{?dist}
Summary:        Cross-platform make system

License:        BSD-3-Clause AND MIT-open-group AND Zlib%{?with_bundled_cppdap: AND Apache-2.0}
URL:            http://www.cmake.org
Source0:        https://github.com/Kitware/CMake/releases/download/v%{version}/%{orig_name}-%{tar_version}.tar.gz
Source1:        %{orig_name}-init.el
Source2:        macros.%{orig_name}.in
Source3:        %{orig_name}.attr
Source4:        %{orig_name}.prov
Source5:        %{orig_name}.req

Patch100:       %{orig_name}-findruby.patch

BuildRequires:  coreutils
BuildRequires:  findutils
BuildRequires:  gcc-c++
BuildRequires:  sed
BuildRequires:  make

%if %{with ncurses}
BuildRequires:  ncurses-devel
%endif

%if %{with emacs}
BuildRequires:  emacs
%endif

%if %{without bootstrap}
BuildRequires:  bzip2-devel
BuildRequires:  curl-devel
BuildRequires:  expat-devel
BuildRequires:  libarchive-devel
BuildRequires:  libuv-devel
BuildRequires:  xz-devel
BuildRequires:  zlib-devel
BuildRequires:  vim-filesystem
%endif

%if %{?scl:1}%{!?scl:0}
Requires:       %{scl_runtime}
%endif
Requires:       %{name}-data = %{version}-%{release}
Requires:       %{name}-rpm-macros = %{version}-%{release}
Requires:       %{name}-filesystem = %{version}-%{release}
Requires:       make

Provides:       bundled(md5-deutsch)
Provides:       bundled(kwsys)
%if %{with bundled_cppdap}
Provides:       bundled(cppdap)
%endif
%if %{with bundled_jsoncpp}
Provides:       bundled(jsoncpp)
%endif
%if %{with bundled_rhash}
Provides:       bundled(rhash)
%endif

%description
CMake is used to control the software compilation process using simple
platform and compiler independent configuration files. CMake generates
native makefiles and workspaces that can be used in the compiler
environment of your choice. CMake is quite sophisticated: it is possible
to support complex environments requiring system configuration, preprocessor
generation, code generation, and template instantiation.

%package        data
Summary:        Common data-files for %{name}
Requires:       %{name} = %{version}-%{release}
Requires:       %{name}-filesystem = %{version}-%{release}
Requires:       %{name}-rpm-macros = %{version}-%{release}
BuildArch:      noarch

%description    data
This package contains common data-files for %{name}.

%package        doc
Summary:        Documentation for %{name}
BuildArch:      noarch

%description    doc
This package contains documentation for %{name}.

%package        filesystem
Summary:        Directories used by CMake modules

%description    filesystem
This package owns all directories used by CMake modules.

%package        rpm-macros
Summary:        Common RPM macros for %{name}
Requires:       rpm
BuildArch:      noarch

%description    rpm-macros
This package contains common RPM macros for %{name}.

%prep
%autosetup -n %{orig_name}-%{tar_version} -p 1
find . -name "*.orig" -delete

%if %{with rpm}
%if %{with python3}
echo '#!%{__python3}' > %{orig_name}.prov
echo '#!%{__python3}' > %{orig_name}.req
%else
echo '#!%{__python2}' > %{orig_name}.prov
echo '#!%{__python2}' > %{orig_name}.req
%endif
tail -n +2 %{SOURCE4} >> %{orig_name}.prov
tail -n +2 %{SOURCE5} >> %{orig_name}.req
%endif

%build
%{?set_build_flags:%{set_build_flags}}
if [ -d "$HOME/.local/usr/include/openssl" ] && [ ! -d /usr/include/openssl ]; then
  export OPENSSL_ROOT_DIR="$HOME/.local/usr"
fi
SRCDIR="$(/usr/bin/pwd)"
mkdir %{_vpath_builddir}
pushd %{_vpath_builddir}
$SRCDIR/bootstrap --prefix=%{_prefix} \
                  --datadir=/share/%{pkg_name} \
                  --docdir=/share/doc/%{pkg_name} \
                  --mandir=/share/man \
                  --%{?with_bootstrap:no-}system-libs \
                  --parallel="$(echo %{?_smp_mflags} | sed -e 's|-j||g' -e 's| ||g')" \
%if %{with bundled_cppdap}
                  --no-system-cppdap \
%endif
%if %{with bundled_rhash}
                  --no-system-librhash \
%endif
%if %{with bundled_jsoncpp}
                  --no-system-jsoncpp \
%endif
%if %{with sphinx}
                  --sphinx-man --sphinx-html \
%else
                  --sphinx-build=%{_bindir}/false \
%endif
                  --%{!?with_gui:no-}qt-gui \
                  -- \
                  -DCMAKE_C_FLAGS_RELEASE:STRING="-O2 -g -DNDEBUG" \
                  -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O2 -g -DNDEBUG" \
                  -DCMAKE_Fortran_FLAGS_RELEASE:STRING="-O2 -g -DNDEBUG" \
                  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
                  -DCMAKE_INSTALL_DO_STRIP:BOOL=OFF
popd
%make_build -C %{_vpath_builddir}

%install
mkdir -p %{buildroot}%{_pkgdocdir}
%make_install -C %{_vpath_builddir} CMAKE_DOC_DIR=%{buildroot}%{_pkgdocdir}
find %{buildroot}%{_datadir}/%{pkg_name} -name "*.orig" -delete
find %{buildroot}%{_datadir}/%{pkg_name}/Modules -type f | xargs chmod -x
[ -n "$(find %{buildroot}%{_datadir}/%{pkg_name}/Modules -name \*.orig)" ] &&
  echo "Found .orig files in %{_datadir}/%{pkg_name}/Modules, rebase patches" &&
  exit 1

# Strip binaries (brp-strip skips PIE shared objects when debug_package is disabled)
find %{buildroot}%{_bindir} -type f -exec /usr/bin/strip -g {} + 2>/dev/null || :

# Install major_version name links
for f in ccmake cmake cpack ctest; do
  [ -f %{buildroot}%{_bindir}/$f ] && ln -sf $f %{buildroot}%{_bindir}/${f}%{major_version}
done

%if %{with emacs}
mkdir -p %{buildroot}%{_emacs_sitelispdir}/%{name} %{buildroot}%{_emacs_sitestartdir}
mv %{buildroot}%{_emacs_sitelispdir}/%{name}-mode.el %{buildroot}%{_emacs_sitelispdir}/%{name}
%{_emacs_bytecompile} %{buildroot}%{_emacs_sitelispdir}/%{name}/%{name}-mode.el
install -p -m 0644 %{SOURCE1} %{buildroot}%{_emacs_sitestartdir}
%else
rm -rf %{buildroot}%{_datadir}/emacs
%endif

# RPM macros
install -p -m0644 -D %{SOURCE2} %{buildroot}%{rpm_macros_dir}/macros.%{name}
sed -i -e "s|@@CMAKE_VERSION@@|%{version}|" \
       -e "s|@@CMAKE_MAJOR_VERSION@@|%{major_version}|" \
       -e "s|/usr/bin/cmake|%{_bindir}/cmake|" \
       -e "s|/usr/bin/ctest|%{_bindir}/ctest|" \
       %{buildroot}%{rpm_macros_dir}/macros.%{name}
touch -r %{SOURCE2} %{buildroot}%{rpm_macros_dir}/macros.%{name}

mkdir -p %{buildroot}%{_libdir}/%{orig_name}

# Install copyright files for main package
find Source Utilities -type f -iname copy\* | while read f; do
  fname=$(basename "$f")
  dir=$(dirname "$f")
  dname=$(basename "$dir")
  cp -p "$f" ./${fname}_${dname}
done
%if %{with bundled_cppdap}
cp -p Utilities/cmcppdap/LICENSE LICENSE.cppdap
cp -p Utilities/cmcppdap/NOTICE NOTICE.cppdap
%endif

# Cleanup pre-installed documentation
rm -rf %{buildroot}%{_docdir}/%{pkg_name}
# Install documentation to _pkgdocdir
mkdir -p %{buildroot}%{_pkgdocdir}
if [ -d %{buildroot}%{_datadir}/%{pkg_name}/Help ]; then
  cp -pr %{buildroot}%{_datadir}/%{pkg_name}/Help %{buildroot}%{_pkgdocdir}
  mv %{buildroot}%{_pkgdocdir}/Help %{buildroot}%{_pkgdocdir}/rst
fi

# create manifests for splitting files and directories for filesystem-package
find %{buildroot}%{_datadir}/%{pkg_name} -type d | \
  sed -e 's!^%{buildroot}!%%dir "!g' -e 's!$!"!g' > data_dirs.mf
find %{buildroot}%{_datadir}/%{pkg_name} -type f | \
  sed -e 's!^%{buildroot}!"!g' -e 's!$!"!g' > data_files.mf
find %{buildroot}%{_libdir}/%{orig_name} -type d | \
  sed -e 's!^%{buildroot}!%%dir "!g' -e 's!$!"!g' > lib_dirs.mf
find %{buildroot}%{_libdir}/%{orig_name} -type f | \
  sed -e 's!^%{buildroot}!"!g' -e 's!$!"!g' > lib_files.mf
find %{buildroot}%{_bindir} -type f -or -type l -or -xtype l | \
  sed -e '/.*-gui$/d' -e '/^$/d' -e 's!^%{buildroot}!"!g' -e 's!$!"!g' >> lib_files.mf

%files -f lib_files.mf
%license Copyright.txt*
%license COPYING*
%if %{with bundled_cppdap}
%license LICENSE.cppdap
%license NOTICE.cppdap
%endif
%doc %dir %{_pkgdocdir}

%files data -f data_files.mf
%dir %{_datadir}/aclocal
%{_datadir}/aclocal/%{orig_name}.m4
%{_datadir}/bash-completion
%{_datadir}/vim

%files doc
%license Copyright.txt*
%license COPYING*
%if %{with bundled_cppdap}
%license LICENSE.cppdap
%license NOTICE.cppdap
%endif
%doc %{_pkgdocdir}

%files filesystem -f data_dirs.mf -f lib_dirs.mf

%files rpm-macros
%{rpm_macros_dir}/macros.%{name}

%changelog
* Sun Oct 11 2026 devtoolset-releng <cooluc@cooluc.com> - 3.31.8-1
- Backport Rocky Linux 10 cmake-3.31.8-1.el10 under SCL devtoolset-16
