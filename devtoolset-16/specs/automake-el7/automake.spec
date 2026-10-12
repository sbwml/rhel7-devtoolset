# automake 1.16.1 backported for CentOS/RHEL 7 under SCL
# Baseline: automake-1.16.1-8.el8.src.rpm (Rocky 8 / AppStream)

%global api_version 1.16

%bcond_with check

%{?scl_package:%global scl devtoolset-16}
%global scl_name devtoolset-16
%global scl_prefix devtoolset-16-
%global pkg_name automake
BuildRequires: scl-utils-build
%{?scl:%scl_package automake}

Summary:    A GNU tool for automatically creating Makefiles
Name:       %{?scl_prefix}automake
Version:    %{api_version}.1
Release:    8%{?dist}

# docs ~> GFDL, sources ~> GPLv2+, mkinstalldirs ~> PD and install-sh ~> MIT
License:    GPLv2+ and GFDL and Public Domain and MIT

Source0:    https://ftp.gnu.org/gnu/automake/%{pkg_name}-%{version}.tar.xz
Source1:    config.sub
Source2:    config.guess

# Keep those patches in 'git format-patch' format (with docs).
%if %{with check}
Patch0:     automake-1.15-disable-vala-tests.patch
%endif

# BZ#1759942
# automake bug#31222 - Don't use '\n' in sed substitution
Patch1:     automake-1.16-pep3147-tweak-fix.patch

# BZ#2209821
# Backport fixes for automake bugs 44239 and 53530
Patch2:     automake-1.16.1-python-version-multiple-digits.patch
Patch3:     0001-python-add-3.10-3.15-to-the-version-search-list.patch

URL:        http://www.gnu.org/software/automake/
Requires:   %{?scl_prefix}autoconf >= 2.65

# requirements not detected automatically (#919810)
Requires:   perl(Thread::Queue)
Requires:   perl(threads)

BuildRequires:  autoconf >= 2.65
BuildRequires:  coreutils
BuildRequires:  findutils
BuildRequires:  make
BuildRequires:  perl-interpreter
BuildRequires:  perl(Thread::Queue)
BuildRequires:  perl(threads)

BuildArch:  noarch

%define __requires_exclude ^perl\(Automake::
%define __provides_exclude ^perl\(Automake::

%description
Automake is a tool for automatically generating `Makefile.in'
files compliant with the GNU Coding Standards.

You should install Automake if you are developing software and would
like to use its ability to automatically generate GNU standard
Makefiles.

%prep
%autosetup -p1 -n %{pkg_name}-%{version}

for f in config.sub config.guess; do
  find . -name "$f" -exec cp -f "%{_sourcedir}/$f" {} \;
done

%if %{with check}
autoreconf -iv || :
%endif

%build
%global _configure_gnuconfig_hack 0
%configure
%make_build
cp m4/acdir/README README.aclocal 2>/dev/null || :
cp contrib/multilib/README README.multilib 2>/dev/null || :

%if %{with check}
%check
make -k %{?_smp_mflags} check %{?TESTS_FLAGS: TESTS="%{TESTS_FLAGS}"} \
    || ( cat ./test-suite.log && false )
%endif

%install
%make_install

mkdir -p %{buildroot}%{_datadir}/aclocal
cat > %{buildroot}%{_datadir}/aclocal/dirlist <<'DIRLIST'
/usr/share/aclocal
DIRLIST

%files
%dir %{_datadir}/aclocal
%{_datadir}/aclocal/dirlist
%license COPYING*
%doc AUTHORS README THANKS NEWS
%doc %{_datadir}/doc/%{pkg_name}/amhello-1.0.tar.gz
%exclude %{_infodir}/dir
%{_bindir}/*
%{_infodir}/*.info*
%{_datadir}/automake-%{api_version}
%{_datadir}/aclocal-%{api_version}
%{_mandir}/man1/*

%changelog
* Wed Jun 28 2023 Frederic Berat <fberat@redhat.com> - 1.16.1-8
- Fix support for detection of python 3.1x (RHBZ#2209821)
