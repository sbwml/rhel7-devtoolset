Name:           xxhash
Version:        0.8.2
Release:        11%{?dist}
Summary:        Extremely fast hash algorithm

License:        BSD-2-Clause AND GPL-2.0-or-later
URL:            https://www.xxhash.com/
Source0:        https://github.com/Cyan4973/xxHash/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  make
BuildRequires:  gcc

%description
xxHash is an Extremely fast Hash algorithm, running at RAM speed
limits. It successfully completes the SMHasher test suite which
evaluates collision, dispersion and randomness qualities of hash
functions. Code is highly portable, and hashes are identical on all
platforms (little / big endian).

%package libs
Summary:        Extremely fast hash algorithm - library
License:        BSD-2-Clause

%description libs
xxHash is an Extremely fast Hash algorithm, running at RAM speed
limits. It successfully completes the SMHasher test suite which
evaluates collision, dispersion and randomness qualities of hash
functions. Code is highly portable, and hashes are identical on all
platforms (little / big endian).

%package devel
Summary:        Extremely fast hash algorithm - development files
License:        BSD-2-Clause
Requires:       %{name}-libs%{?_isa} = %{version}-%{release}
Provides:       %{name}-static = %{version}-%{release}

%description devel
Development files for the xxhash library

%prep
%setup -q -n xxHash-%{version}

%build
%ifarch %{ix86} x86_64
%global dispatch 1
%global moreflags_dispatch -DXXH_X86DISPATCH_ALLOW_AVX
%else
%global dispatch 0
%global moreflags_dispatch %{nil}
%endif

make %{?_smp_mflags} \
    MOREFLAGS="%{optflags} %{?__global_ldflags} %{moreflags_dispatch}" \
    DISPATCH=%{dispatch}

%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix} LIBDIR=%{_libdir}
rm -f %{buildroot}/%{_libdir}/libxxhash.a

%check
make check
make test-xxhsum-c

%post libs -p /sbin/ldconfig
%postun libs -p /sbin/ldconfig

%files
%{_bindir}/xxh*sum
%{_mandir}/man1/xxh*sum.1*
%doc cli/README.md

%files libs
%{_libdir}/libxxhash.so.*
%doc README.md

%files devel
%{_includedir}/xxhash.h
%{_includedir}/xxh3.h
%{_libdir}/libxxhash.so
%{_libdir}/pkgconfig/libxxhash.pc

%changelog
* Sun Oct 11 2026 devtoolset-releng <cooluc@cooluc.com> - 0.8.2-11
- Backport EL10 xxhash baseline for CentOS 7
