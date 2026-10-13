#!/usr/bin/env python3
"""Inject devtoolset-16 SCL wiring into EL10 specs lacking native SCL support.

Usage: scl-wire.py <spec> <pkgname>
"""
import sys, re

path, pkg = sys.argv[1], sys.argv[2]
src = open(path, encoding='utf-8', errors='replace').read()

if 'scl_package' in src:
    sys.exit(0)

if pkg in ('xxhash', 'babeltrace', 'boost', 'boost183'):
    sys.exit(0)

pre = (
    "# --- devtoolset-16 SCL wiring (injected by scl-wire.py) ---\n"
    "%global scl devtoolset-16\n"
    "%global scl_name devtoolset-16\n"
    "%global scl_prefix devtoolset-16-\n"
    "%global pkg_name " + pkg + "\n"
    "BuildRequires: scl-utils-build\n"
    "%{?scl_package:%scl_package " + pkg + "}\n"
    "# ----------------------------------------------------------\n"
)
m = re.search(r'^\s*Name\s*:', src, re.M)
if not m:
    sys.exit(0)
src = src[:m.start()] + pre + src[m.start():]

# Prefix package name to avoid collisions with system packages
src = re.sub(r'^(\s*Name\s*:\s*)', r'\1%{?scl_prefix}', src, count=1, flags=re.M)

# Preserve upstream package name in Source/SourceN declarations
src = re.sub(r'^(\s*(?:NoSource|Source)\d*\s*:.*)$',
             lambda mm: mm.group(1).replace('%{name}', '%{pkg_name}'),
             src, flags=re.M)

# Preserve upstream package name in %setup / %autosetup
src = re.sub(r'^(\s*%(?:auto)?setup\b.*)$',
             lambda mm: mm.group(1).replace('%{name}', '%{pkg_name}'),
             src, flags=re.M)

# Map %find_lang %{name} to %{pkg_name}
src = re.sub(r'^%find_lang\s+%\{name\}\s*$',
             '%find_lang %{pkg_name} || touch %{pkg_name}.lang', src, flags=re.M)
src = re.sub(r'-f\s+%\{name\}\.lang\b', '-f %{pkg_name}.lang', src)
src = re.sub(r'>>\s*%\{name\}\.lang\b', '>> %{pkg_name}.lang', src)

def _scl_prefix_path(m):
    opt, sub = m.group('opt'), m.group('sub') or ''
    return f'-D{opt}:PATH=%{{_prefix}}{sub}'
src = re.sub(r'-D(?P<opt>[A-Za-z0-9_]+)(?::PATH)?=/usr(?P<sub>/[A-Za-z0-9_./-]*)?',
             _scl_prefix_path, src)
src = re.sub(r'\s--log-level=\S+', '', src)
# Expand CMake macros explicitly on EL7 to prevent RPM 4.11 continuation parse issues
src = re.sub(r'^\s*%cmake_build\b.*$', r'%__make %{?_smp_mflags}', src, flags=re.M)
src = re.sub(r'^\s*%cmake_install\b.*$',
             r'%__make install DESTDIR=%{buildroot}', src, flags=re.M)

def _cmake_head(m):
    return f'{m.group("indent")}%__cmake .{m.group("rest")}'
src = re.sub(r'^(?P<indent>\s*)%cmake\b(?P<rest>[^\n]*)$', _cmake_head, src, flags=re.M)

if pkg == 'dyninst':
    import os
    _binc = '/usr/include/boost183' if os.path.exists('/usr/include/boost183') else '/usr/include/boost169'
    src = src.replace(
        '%__cmake . ',
        '%__cmake . -DBoost_DIR:PATH=/usr/local/lib64/cmake/Boost '
        '-DBoost_ROOT_DIR:PATH=/usr '
        f'-DBoost_INCLUDE_DIR:PATH={_binc} '
        '-DTBB_DIR:PATH=/usr/local/lib64/cmake/TBB ')
    src = re.sub(r'-DENABLE_DEBUGINFOD=1', '-DENABLE_DEBUGINFOD=0', src)

if pkg == 'dyninst':
    src = src.replace('LDFLAGS="$LDFLAGS $RPM_LD_FLAGS"',
                      'LDFLAGS="$LDFLAGS $RPM_LD_FLAGS -lpthread"')
    _boost_link = ' '.join(
        '-lboost_' + c for c in
        ('atomic', 'chrono', 'date_time', 'filesystem', 'thread', 'timer'))
    _link_flags = '-lpthread ' + _boost_link
    _extra = ('-DCMAKE_INSTALL_PREFIX:PATH=%{_prefix} '
              '-DCMAKE_CXX_STANDARD_LIBRARIES:STRING="' + _link_flags + '" '
              '-DCMAKE_EXE_LINKER_FLAGS:STRING="' + _link_flags + '" '
              '-DCMAKE_SHARED_LINKER_FLAGS:STRING="' + _link_flags + '"')
    src = src.replace('-DCMAKE_INSTALL_PREFIX:PATH=%{_prefix}', _extra)
    _inject = (
        '\n# --- devtoolset-16: C7 elf.h compat header ---\n'
        'cp -f %{_sourcedir}/dyninst-elf-compat.h '
        '%{dyninst_base}/elf/h/dyninst-elf-compat.h\n'
        'grep -q "dyninst-elf-compat.h" %{dyninst_base}/elf/h/Elf_X.h || \\\n'
        '  sed -i \'s|^#include "libelf.h"|#include "libelf.h"\\n'
        '#include "dyninst-elf-compat.h"|\' %{dyninst_base}/elf/h/Elf_X.h\n'
    )
    src = src.replace('\n%build', _inject + '\n%build', 1)

src = re.sub(r'^(\s*tar\b.*%\{name\}-%\{version\}.*)$',
             lambda mm: mm.group(1).replace('%{name}', '%{pkg_name}'),
             src, flags=re.M)

def _setup_addn(m):
    line = m.group(0)
    if '-n ' in line or '--name' in line or '-T' in line:
        return line
    indent, kind, rest = m.group('indent'), m.group('kind') or '', m.group('rest')
    if kind == 'auto':
        return f'{indent}%autosetup{rest} -n %{{pkg_name}}-%{{version}}'
    return f'{indent}%setup -q -n %{{pkg_name}}-%{{version}}'
src = re.sub(r'^(?P<indent>\s*)%(?P<kind>auto)?setup\b(?P<rest>[^\n]*)$', _setup_addn, src, flags=re.M)
open(path, 'w', encoding='utf-8').write(src)
