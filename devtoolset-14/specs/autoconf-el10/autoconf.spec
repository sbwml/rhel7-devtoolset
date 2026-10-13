# devtoolset-14 / autoconf 2.71
# Baseline: autoconf-2.71-13.el10.src.rpm (Rocky Linux 10 AppStream)
%{?scl_package:%global scl devtoolset-14}
%global scl_name devtoolset-14
%global scl_prefix devtoolset-14-
%global pkg_name autoconf
BuildRequires: scl-utils-build
%{?scl:%scl_package autoconf}

Summary:        A GNU tool for automatically configuring source code
Name:           %{?scl_prefix}autoconf
Version:        2.71
Release:        13%{?dist}
License:        GPL-2.0-or-later AND GPL-3.0-or-later AND GPL-3.0-or-later WITH Autoconf-exception-generic-3.0 AND GFDL-1.3-or-later AND FSFAP AND X11 AND LicenseRef-Fedora-Public-Domain
Source0:        https://ftp.gnu.org/gnu/autoconf/%{pkg_name}-%{version}.tar.xz
Source1:        config.site
Source2:        autoconf-init.el
URL:            https://www.gnu.org/software/autoconf/

# Cherry-pick from upstream f460883035ef849a2248b1713f711292ec19f4f0
Patch0:         0001-_AC_PROG_CXX_STDCXX_EDITION_TRY-fix-typo-in-variable.patch
# Cherry-pick from upstream 412166e185c00d6eacbe67dfcb0326f622ec4020
Patch1:         0001-Fix-testsuite-failures-with-bash-5.2.patch

BuildArch:      noarch

%bcond_with check
%bcond_with autoconf_enables_emacs

BuildRequires:      perl
Requires:           perl(File::Compare)
Requires:           perl-interpreter
BuildRequires:      m4 >= 1.4.14
Requires:           m4 >= 1.4.14
%if %{with autoconf_enables_emacs}
Requires:           emacs-filesystem
BuildRequires:      emacs
%endif
BuildRequires:      perl-generators
BuildRequires:      perl-macros
BuildRequires:      perl(Data::Dumper)
BuildRequires:      perl(Text::ParseWords)

BuildRequires:      help2man
BuildRequires:      make

%if %{with check}
BuildRequires:      gcc-gfortran
%endif

# filter out bogus perl(Autom4te*) dependencies
%global __requires_exclude %{?__requires_exclude:%__requires_exclude|}^perl\\(Autom4te::
%global __provides_exclude %{?__provides_exclude:%__provides_exclude|}^perl\\(Autom4te::

%description
GNU's Autoconf is a tool for configuring source code and Makefiles.
Using Autoconf, programmers can create portable and configurable
packages, since the person building the package is allowed to
specify various configuration options.

You should install Autoconf if you are developing software and
would like to create shell scripts that configure your source code
packages. If you are installing Autoconf, you will also need to
install the GNU m4 package.

Note that the Autoconf package is not required for the end-user who
may be configuring software with an Autoconf-generated script;
Autoconf is only required for the generation of the scripts, not
their use.

%prep
%autosetup -n %{pkg_name}-%{version} -p1

%build
%if %{with autoconf_enables_emacs}
export EMACS=%{_bindir}/emacs
%else
export EMACS=%{_bindir}/false
%endif
%configure \
    %{?with_autoconf_enables_emacs:--with-lispdir=%{_emacs_sitelispdir}/autoconf}
%make_build

%check
%if %{with check}
make check %{?_smp_mflags}
%endif

%install
%make_install
mkdir -p %{buildroot}%{_datadir}
install -p -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/config.site

%if %{with autoconf_enables_emacs}
mkdir -p %{buildroot}%{_emacs_sitestartdir}
install -p -m 0644 %{SOURCE2} %{buildroot}%{_emacs_sitestartdir}
%endif

%files
%license COPYING*
%{_bindir}/*
%{_infodir}/autoconf.info*
%exclude %{_infodir}/standards*
%exclude %{_infodir}/dir
%{_datadir}/autoconf/
%{_datadir}/config.site
%if %{with autoconf_enables_emacs}
%{_datadir}/emacs/site-lisp/*
%endif
%{_mandir}/man1/*
%doc AUTHORS ChangeLog NEWS README THANKS TODO

%changelog
* Sun Oct 11 2026 devtoolset-releng <cooluc@cooluc.com> - 2.71-13
- Backport Rocky Linux 10 autoconf-2.71-13.el10 under SCL devtoolset-14
