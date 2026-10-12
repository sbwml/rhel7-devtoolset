%global __python /usr/bin/python3
%global scl devtoolset-14
%global scl_prefix devtoolset-14-
%global scl_name %scl
%scl_package %scl

Summary: Package that installs %scl
Name: %scl_name
Version: 14.1
Release: 1%{?dist}
License: GPLv2+
Group: Applications/File
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Source0: README
Source1: gts-annobin-plugin-select.sh

# The base package requires just the toolchain and the perftools.
Requires: %{scl_prefix}toolchain %{scl_prefix}perftools
Obsoletes: %{name} < %{version}-%{release}
Obsoletes: %{scl_prefix}dockerfiles < %{version}-%{release}

BuildRequires: scl-utils-build >= 20120927-11
BuildRequires: iso-codes
BuildRequires: help2man
%if 0%{?rhel} >= 8
BuildRequires: python3-devel
%endif

%global rrcdir %{_scl_root}/usr/lib/rpm/redhat

%description
This is the main package for %scl Software Collection.

%package runtime
Summary: Package that handles %scl Software Collection.
Group: Applications/File
Requires: scl-utils >= 20120927-11
Obsoletes: %{name}-runtime < %{version}-%{release}

%description runtime
Package shipping essential scripts to work with %scl Software Collection.

%package build
Summary: Package shipping basic build configuration
Group: Applications/File
Requires: %{scl_prefix}runtime
Requires: scl-utils-build >= 20120927-11
Obsoletes: %{name}-build < %{version}-%{release}

%description build
Package shipping essential configuration macros to build %scl Software Collection.

%package toolchain
Summary: Package shipping basic toolchain applications
Group: Applications/File
Requires: %{scl_prefix}runtime
Requires: %{scl_prefix}gcc %{scl_prefix}gcc-c++ %{scl_prefix}gcc-gfortran
Requires: %{scl_prefix}binutils %{scl_prefix}gdb %{scl_prefix}strace
Requires: %{scl_prefix}dwz %{scl_prefix}elfutils
Requires: %{scl_prefix}ltrace %{scl_prefix}make
Requires: %{scl_prefix}annobin-plugin-gcc
Obsoletes: %{name}-toolchain < %{version}-%{release}

%description toolchain
Package shipping basic toolchain applications (compiler, debugger, ...)

%package perftools
Summary: Package shipping performance tools
Group: Applications/File
Requires: %{scl_prefix}runtime
Requires: %{scl_prefix}systemtap %{scl_prefix}valgrind
%ifarch x86_64 ppc64le aarch64
Requires: %{scl_prefix}dyninst
%endif
Obsoletes: %{name}-perftools < %{version}-%{release}

%description perftools
Package shipping performance tools (systemtap, valgrind)

%prep
%setup -c -T

# This section generates README file from a template and creates man page
# from that file, expanding RPM macros in the template file.
cat <<'EOF' | tee README
%{expand:%(cat %{SOURCE0})}
EOF

%build

# Temporary helper script used by help2man.
cat <<\EOF | tee h2m_helper
#!/bin/sh
if [ "$1" = "--version" ]; then
  printf '%%s' "%{?scl_name} %{version} Software Collection"
else
  cat README
fi
EOF
chmod a+x h2m_helper
# Generate the man page.
help2man -N --section 7 ./h2m_helper -o %{?scl_name}.7

# Enable collection script
# ========================
cat <<EOF >enable
# General environment variables
export PATH=%{_bindir}\${PATH:+:\${PATH}}
export MANPATH=%{_mandir}\${MANPATH:+:\${MANPATH}}
export INFOPATH=%{_infodir}\${INFOPATH:+:\${INFOPATH}}
export PCP_DIR=%{_scl_root}
# bz847911 workaround:
# we need to evaluate rpm's installed run-time % { _libdir }, not rpmbuild time
# or else /etc/ld.so.conf.d files?
rpmlibdir=\$(rpm --eval "%%{_libdir}")
# bz1017604: On 64-bit hosts, we should include also the 32-bit library path.
# bz1873882: On 32-bit hosts, we should include also the 64-bit library path.
# bz2027377: Avoid unbound variables
if [ "\$rpmlibdir" != "\${rpmlibdir/lib64/}" ]; then
  rpmlibdir32=":%{_scl_root}\${rpmlibdir/lib64/lib}"
  dynpath32="\$rpmlibdir32/dyninst"
  rpmlibdir64=
  dynpath64=
else
  rpmlibdir64=":%{_scl_root}\${rpmlibdir/lib/lib64}"
  dynpath64="\$rpmlibdir64/dyninst"
  rpmlibdir32=
  dynpath32=
fi
# Add SCL dyninst to LD_LIBRARY_PATH, both 64- and 32-bit paths.
export LD_LIBRARY_PATH=%{_scl_root}\$rpmlibdir/dyninst\$dynpath64\$dynpath32\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
# Now prepend the usual /opt/.../usr/lib{64,}.
export LD_LIBRARY_PATH=%{_scl_root}\$rpmlibdir\$rpmlibdir64\$rpmlibdir32\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
export PKG_CONFIG_PATH=%{_libdir}/pkgconfig\${PKG_CONFIG_PATH:+:\${PKG_CONFIG_PATH}}
EOF

%install
(%{scl_install})

# This allows users to build packages using DTS/GTS.
cat >> %{buildroot}%{_root_sysconfdir}/rpm/macros.%{scl}-config << EOF
%%enable_devtoolset14 %%global ___build_pre %%{___build_pre}; source scl_source enable %{scl} || :
EOF

mkdir -p %{buildroot}%{_scl_root}/etc/alternatives %{buildroot}%{_scl_root}/var/lib/alternatives

install -d -m 755 %{buildroot}%{_scl_scripts}
install -p -m 755 enable %{buildroot}%{_scl_scripts}/

# Other directories that should be owned by the runtime
install -d -m 755 %{buildroot}%{_datadir}/appdata
# Otherwise unowned perl directories
install -d -m 755 %{buildroot}%{_libdir}/perl5
install -d -m 755 %{buildroot}%{_libdir}/perl5/vendor_perl
install -d -m 755 %{buildroot}%{_libdir}/perl5/vendor_perl/auto

# Install generated man page.
install -d -m 755 %{buildroot}%{_mandir}/man7
install -p -m 644 %{?scl_name}.7 %{buildroot}%{_mandir}/man7/

# Install the plugin selector trigger script.
mkdir -p %{buildroot}%{rrcdir}
install -p -m 755 %{SOURCE1} %{buildroot}%{rrcdir}/

# This trigger is used to decide which version of the annobin plugin for gcc
# should be used.  See comments in the script for full details.

%triggerin runtime -- %{scl_prefix}annobin-plugin-gcc %{scl_prefix}gcc-plugin-annobin
%{rrcdir}/gts-annobin-plugin-select.sh %{_scl_root}
%end

# We also trigger when annobin is uninstalled.  This allows us to switch
# over to the gcc generated version of the plugin.  It does not matter if
# gcc is uninstalled, since if that happens the plugin cannot be used.

%triggerpostun runtime -- %{scl_prefix}annobin-plugin-gcc
%{rrcdir}/gts-annobin-plugin-select.sh %{_scl_root}
%end

%files
%doc README
%{_mandir}/man7/%{?scl_name}.*

%files runtime
%attr(0755,-,-) %{rrcdir}/gts-annobin-plugin-select.sh
%scl_files
%attr(0644,root,root) %verify(not md5 size mtime) %ghost %config(missingok,noreplace) %{_sysconfdir}/selinux-equiv.created
%dir %{_scl_root}/etc/alternatives
%dir %{_datadir}/appdata

%files build
%{_root_sysconfdir}/rpm/macros.%{scl}*

%files toolchain

%files perftools

%post runtime
if [ ! -f %{_sysconfdir}/selinux-equiv.created ]; then
  _semanage=
  if [ -x /usr/sbin/semanage ]; then
    _semanage="/usr/sbin/semanage"
  elif command -v semanage >/dev/null 2>&1; then
    _semanage="semanage"
  fi
  if [ -n "$_semanage" ]; then
    $_semanage fcontext -a -e / %{_scl_root} >/dev/null 2>&1 || :
    if [ -x /sbin/restorecon ]; then
      /sbin/restorecon -R %{_scl_root} >/dev/null 2>&1 || :
    elif command -v restorecon >/dev/null 2>&1; then
      restorecon -R %{_scl_root} >/dev/null 2>&1 || :
    fi
    touch %{_sysconfdir}/selinux-equiv.created
  fi
fi

%preun runtime
[ $1 = 0 ] && rm -f %{_sysconfdir}/selinux-equiv.created || :

%postun runtime
if [ $1 = 0 ]; then
  _semanage=
  if [ -x /usr/sbin/semanage ]; then
    _semanage="/usr/sbin/semanage"
  elif command -v semanage >/dev/null 2>&1; then
    _semanage="semanage"
  fi
  if [ -n "$_semanage" ]; then
    $_semanage fcontext -d %{_scl_root} >/dev/null 2>&1 || :
    if [ -d %{_scl_root} ]; then
      if [ -x /sbin/restorecon ]; then
        /sbin/restorecon -R %{_scl_root} >/dev/null 2>&1 || :
      elif command -v restorecon >/dev/null 2>&1; then
        restorecon -R %{_scl_root} >/dev/null 2>&1 || :
      fi
    fi
  fi
fi

%changelog
* Fri Oct 11 2025 devtoolset-14 <devtoolset-14@users.noreply.github.com> - 14.1-1
- Use devtoolset-14/toolchain/perftools layout (based on devtoolset-11 SCL skeleton)
- Provide /opt/rh/devtoolset-14/enable entry point
