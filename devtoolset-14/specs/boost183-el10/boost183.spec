%global version_suffix 183
%global version_enc 1_83_0
%global real_name boost
%global sonamever 1.83.0

Name:           boost%{version_suffix}
Summary:        The free peer-reviewed portable C++ source libraries
Version:        1.83.0
Release:        8%{?dist}
License:        BSL-1.0 AND MIT AND Python-2.0.1
URL:            http://www.boost.org

Source0:        https://boostorg.jfrog.io/artifactory/main/release/%{version}/source/%{real_name}_%{version_enc}.tar.bz2
Source1:        libboost_thread.so
Source2:        b2.1

Patch0:         boost-1.81.0-build-optflags.patch
Patch1:         boost-1.78.0-no-rpath.patch
Patch2:         boost-1.73.0-cmakedir.patch
Patch3:         boost-1.78.0-b2-build-flags.patch
Patch4:         boost-1.76.0-random-test.patch
Patch5:         boost-1.76.0-fix-narrowing-conversions-for-ppc.patch
Patch6:         boost-1.81-phoenix-multiple-defn.patch
Patch7:         boost-1.81.0-random-test-fixes.patch
Patch8:         boost-1.83-regex-test-fixes.patch
Patch9:         boost-1.83-fix-no-member-named_that_error.patch
Patch10:        boost-1.83-context-arm64-bti-hint.patch

BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  m4
BuildRequires:  bzip2-devel
BuildRequires:  zlib-devel

Requires:       %{name}-atomic%{?_isa} = %{version}-%{release}
Requires:       %{name}-chrono%{?_isa} = %{version}-%{release}
Requires:       %{name}-container%{?_isa} = %{version}-%{release}
Requires:       %{name}-date-time%{?_isa} = %{version}-%{release}
Requires:       %{name}-filesystem%{?_isa} = %{version}-%{release}
Requires:       %{name}-program-options%{?_isa} = %{version}-%{release}
Requires:       %{name}-regex%{?_isa} = %{version}-%{release}
Requires:       %{name}-serialization%{?_isa} = %{version}-%{release}
Requires:       %{name}-system%{?_isa} = %{version}-%{release}
Requires:       %{name}-thread%{?_isa} = %{version}-%{release}
Requires:       %{name}-timer%{?_isa} = %{version}-%{release}

%description
Boost provides free peer-reviewed portable C++ source libraries. The emphasis
is on libraries which work well with the C++ Standard Library. This package
provides modern Boost 1.83 for CentOS 7 installed in parallel without
conflicting with the system Boost 1.53.

%package atomic
Summary:        Run-time component of boost atomic library
%description atomic
Run-time support for Boost.Atomic library.

%package chrono
Summary:        Run-time component of boost chrono library
%description chrono
Run-time support for Boost.Chrono library.

%package container
Summary:        Run-time component of boost container library
%description container
Run-time support for Boost.Container library.

%package date-time
Summary:        Run-time component of boost date-time library
%description date-time
Run-time support for Boost.DateTime library.

%package filesystem
Summary:        Run-time component of boost filesystem library
%description filesystem
Run-time support for Boost.Filesystem library.

%package program-options
Summary:        Run-time component of boost program_options library
%description program-options
Run-time support for Boost.ProgramOptions library.

%package regex
Summary:        Run-time component of boost regex library
%description regex
Run-time support for Boost.Regex library.

%package serialization
Summary:        Run-time component of boost serialization library
%description serialization
Run-time support for Boost.Serialization library.

%package system
Summary:        Run-time component of boost system library
%description system
Run-time support for Boost.System library.

%package thread
Summary:        Run-time component of boost thread library
Requires:       %{name}-system%{?_isa} = %{version}-%{release}
%description thread
Run-time support for Boost.Thread library.

%package timer
Summary:        Run-time component of boost timer library
Requires:       %{name}-chrono%{?_isa} = %{version}-%{release}
%description timer
Run-time support for Boost.Timer library.

%package devel
Summary:        The Boost C++ Headers and Development Libraries
Provides:       boost183-devel = %{version}-%{release}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Headers and shared library symlinks for Boost 1.83.

%prep
%setup -q -n %{real_name}_%{version_enc}
%patch -P0 -p1
%patch -P1 -p1
%patch -P2 -p1
%patch -P3 -p1
%patch -P4 -p1
%patch -P5 -p1
%patch -P6 -p1
%patch -P7 -p1
%patch -P8 -p1
%patch -P9 -p1
%patch -P10 -p1

%build
./bootstrap.sh --with-toolset=gcc

./b2 -d+2 -q %{?_smp_mflags} \
    --without-mpi --without-graph_parallel --without-python \
    --build-dir=serial \
    variant=release threading=multi debug-symbols=on pch=off \
    stage

%install
./b2 -d+2 -q %{?_smp_mflags} \
    --without-mpi --without-graph_parallel --without-python \
    --build-dir=serial \
    --prefix=%{buildroot}%{_prefix} \
    --libdir=%{buildroot}%{_libdir} \
    variant=release threading=multi debug-symbols=on pch=off \
    install

mkdir -p %{buildroot}%{_includedir}/boost%{version_suffix}
mv %{buildroot}%{_includedir}/boost %{buildroot}%{_includedir}/boost%{version_suffix}/

mkdir -p %{buildroot}%{_libdir}/boost%{version_suffix}
for f in %{buildroot}%{_libdir}/libboost_*.so; do
    [ -L "$f" ] || continue
    mv "$f" %{buildroot}%{_libdir}/boost%{version_suffix}/
done

m4 -DVERSION=%{sonamever} %{SOURCE1} > %{buildroot}%{_libdir}/boost%{version_suffix}/libboost_thread.so
chmod 755 %{buildroot}%{_libdir}/boost%{version_suffix}/libboost_thread.so

if [ -d %{buildroot}%{_libdir}/cmake ]; then
    mkdir -p %{buildroot}%{_libdir}/boost%{version_suffix}/
    mv %{buildroot}%{_libdir}/cmake %{buildroot}%{_libdir}/boost%{version_suffix}/
fi

rm -f %{buildroot}%{_libdir}/*.a %{buildroot}%{_bindir}/b2

%post atomic -p /sbin/ldconfig
%postun atomic -p /sbin/ldconfig
%post chrono -p /sbin/ldconfig
%postun chrono -p /sbin/ldconfig
%post container -p /sbin/ldconfig
%postun container -p /sbin/ldconfig
%post date-time -p /sbin/ldconfig
%postun date-time -p /sbin/ldconfig
%post filesystem -p /sbin/ldconfig
%postun filesystem -p /sbin/ldconfig
%post program-options -p /sbin/ldconfig
%postun program-options -p /sbin/ldconfig
%post regex -p /sbin/ldconfig
%postun regex -p /sbin/ldconfig
%post serialization -p /sbin/ldconfig
%postun serialization -p /sbin/ldconfig
%post system -p /sbin/ldconfig
%postun system -p /sbin/ldconfig
%post thread -p /sbin/ldconfig
%postun thread -p /sbin/ldconfig
%post timer -p /sbin/ldconfig
%postun timer -p /sbin/ldconfig

%files
# Umbrella metapackage

%files atomic
%{_libdir}/libboost_atomic*.so.%{sonamever}

%files chrono
%{_libdir}/libboost_chrono*.so.%{sonamever}

%files container
%{_libdir}/libboost_container*.so.%{sonamever}

%files date-time
%{_libdir}/libboost_date_time*.so.%{sonamever}

%files filesystem
%{_libdir}/libboost_filesystem*.so.%{sonamever}

%files program-options
%{_libdir}/libboost_program_options*.so.%{sonamever}

%files regex
%{_libdir}/libboost_regex*.so.%{sonamever}

%files serialization
%{_libdir}/libboost_serialization*.so.%{sonamever}
%{_libdir}/libboost_wserialization*.so.%{sonamever}

%files system
%{_libdir}/libboost_system*.so.%{sonamever}

%files thread
%{_libdir}/libboost_thread*.so.%{sonamever}

%files timer
%{_libdir}/libboost_timer*.so.%{sonamever}

%files devel
%{_includedir}/boost%{version_suffix}
%{_libdir}/boost%{version_suffix}

%changelog
* Sun Oct 11 2026 devtoolset-releng <cooluc@cooluc.com> - 1.83.0-8
- Backport EL10 Boost 1.83 baseline as parallel boost183 for CentOS 7
