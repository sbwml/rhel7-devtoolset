Name:           babeltrace
Version:        1.5.11
Release:        8%{?dist}
Summary:        Trace Viewer and Converter, mainly for the Common Trace Format
License:        MIT AND GPL-3.0-or-later WITH Bison-exception-2.2 AND LGPL-2.1-only AND BSD-4-Clause-UC
URL:            https://www.efficios.com/babeltrace
Source0:        https://www.efficios.com/files/%{name}/%{name}-%{version}.tar.bz2
Patch0:         babeltrace-getaddrinfo.patch

BuildRequires:  bison >= 2.4
BuildRequires:  flex >= 2.5.35
BuildRequires:  glib2-devel >= 2.22.0
BuildRequires:  libuuid-devel
BuildRequires:  popt-devel >= 1.13
BuildRequires:  elfutils-devel >= 0.154
BuildRequires:  autoconf automake libtool
BuildRequires:  make gcc

Requires:       lib%{name}%{?_isa} = %{version}-%{release}

%description
This project provides trace read and write libraries, as well as a trace
converter. A plugin can be created for any trace format to allow its conversion
to/from another trace format.

The main format expected to be converted to/from is the Common Trace
Format (CTF). See http://www.efficios.com/ctf.

%package -n lib%{name}
Summary:        Common Trace Format Babel Tower

%description -n lib%{name}
This project provides trace read and write libraries, as well as a trace
converter. A plugin can be created for any trace format to allow its conversion
to/from another trace format.

%package -n lib%{name}-devel
Summary:        Common Trace Format Babel Tower development files
Requires:       lib%{name}%{?_isa} = %{version}-%{release} glib2-devel

%description -n lib%{name}-devel
This project provides development headers and libraries for Babeltrace.

%prep
%setup -q
%patch -P0 -p1

%build
autoreconf -vif
%configure --disable-static --disable-python-bindings
make %{?_smp_mflags} V=1

%install
make DESTDIR=%{buildroot} install
find %{buildroot} -type f -name "*.la" -delete

%post -n lib%{name} -p /sbin/ldconfig
%postun -n lib%{name} -p /sbin/ldconfig

%files
%doc ChangeLog
%{_bindir}/%{name}*
%{_mandir}/man1/*.1*

%files -n lib%{name}
%doc doc/API.txt std-ext-lib.txt
%{_libdir}/*.so.*

%files -n lib%{name}-devel
%{_prefix}/include/*
%{_libdir}/*.so
%{_libdir}/pkgconfig/babeltrace.pc
%{_libdir}/pkgconfig/babeltrace-ctf.pc

%changelog
* Sun Oct 11 2026 devtoolset-releng <cooluc@cooluc.com> - 1.5.11-8
- Backport EL10 babeltrace baseline for CentOS 7
