# devtoolset-14 / make 4.4.1
# Baseline: make-4.4.1-9.el10.src.rpm (Rocky Linux 10 BaseOS)
%{?scl_package:%global scl devtoolset-14}
%global scl_prefix devtoolset-14-
BuildRequires: scl-utils-build
%{?scl:%scl_package make}

Name:           %{?scl_prefix}make
Epoch:          1
Version:        4.4.1
Release:        9%{?dist}
Summary:        A GNU tool which simplifies the build process for users
License:        GPL-3.0-or-later AND LGPL-2.1-or-later AND GFDL-1.3-or-later AND FSFULLR
URL:            http://www.gnu.org/software/make/
Source0:        ftp://ftp.gnu.org/gnu/make/make-%{version}.tar.gz

Patch0:         make-4.3-getcwd.patch
Patch1:         make-4.0-noclock_gettime.patch
Patch2:         make-4.3-j8k.patch

%if 0%{?rhel} > 0
%bcond_with guile
%else
%bcond_without guile
%endif

%if %{?scl:1}%{!?scl:0}
Requires: %{scl_runtime}
%endif

Provides:       make-latest = %{version}-%{release}
Provides:       make441 = %{version}-%{release}

BuildRequires:  make
BuildRequires:  autoconf, automake, gettext-devel
BuildRequires:  procps
BuildRequires:  perl
BuildRequires:  gcc
%if 0%{?with_guile:1}%{!?with_guile:0}
BuildRequires:  pkgconfig(guile-3.0)
%endif

%description
A GNU tool for controlling the generation of executables and other
non-source files of a program from the program's source files. Make
allows users to build and install packages without any significant
knowledge about the details of the build process. The details about
how the program should be built are provided for make in the program's
makefile.

%package devel
Summary:        Header file for externally visible definitions
%description devel
gnumake.h, for writing plugins against GNU make.

%prep
%autosetup -n make-%{version} -p1
rm -f tests/scripts/features/parallelism.orig

%build
%if 0%{?rhel} > 0 && 0%{?rhel} <= 7
# EL7 automake is too old for autoreconf; use shipped configure directly.
%else
autoreconf -vfi
%endif
%configure \
%if 0%{?with_guile:1}%{!?with_guile:0}
    --with-guile
%else
    --without-guile
%endif

%make_build

%install
%make_install
ln -sf make %{buildroot}%{_bindir}/gmake
ln -sf make.1 %{buildroot}%{_mandir}/man1/gmake.1
rm -f %{buildroot}%{_infodir}/dir

# SCL integration
%if %{?scl:1}%{!?scl:0}
install -d -m 755 %{buildroot}/etc/scl/prefixes
dirname %{_scl_root} > devtoolset-14.prefix
install -p -m 644 devtoolset-14.prefix %{buildroot}/etc/scl/prefixes/devtoolset-14

echo "export PATH=%{_scl_root}/usr/bin:\$PATH" > enable.scl
echo "export LD_LIBRARY_PATH=%{_scl_root}/usr/lib64:%{_scl_root}/usr/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}" >> enable.scl
install -p -m 755 enable.scl %{buildroot}/%{_scl_root}/enable
%endif

%find_lang make

%check
echo ============TESTING===============
/usr/bin/env LANG=C make check && true
echo ============END TESTING===========

%files -f make.lang
%license COPYING
%doc NEWS README AUTHORS
%{_scl_root}/usr/bin/*
%{_scl_root}/usr/share/man/man*/*
%{_scl_root}/usr/share/info/*.info*
%if %{?scl:1}%{!?scl:0}
/etc/scl/prefixes/devtoolset-14
%{_scl_root}/enable
%endif

%files devel
%{_scl_root}/usr/include/gnumake.h

%changelog
* Sun Oct 12 2025 devtoolset-14 <devtoolset-14@users.noreply.github.com> - 1:4.4.1-9
- Rebase to Rocky Linux 10 make-4.4.1-9.el10, SCL namespace devtoolset-14
