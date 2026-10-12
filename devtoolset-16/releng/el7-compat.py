#!/usr/bin/env python3
"""CentOS 7 / RPM 4.11 compatibility rewrite for EL10 specs.

Usage: el7-compat.py <spec>
Modifies the spec in place.
"""
import os, sys, re

path = sys.argv[1]
s = open(path, encoding='utf-8', errors='replace').read()
orig = s

# Strip %dnl (RPM 4.15+)
s = re.sub(r'^%dnl(?: .*)?$', '', s, flags=re.M)

# Rewrite %{with X} / %{without X} to classical RPM syntax
s = re.sub(r'%\{with\s+([A-Za-z0-9_]+)\}', r'%{?with_\1:1}%{!?with_\1:0}', s)
s = re.sub(r'%\{without\s+([A-Za-z0-9_]+)\}', r'%{?without_\1:1}%{!?without_\1:0}', s)

def _add_plugin_else(src, flag):
    pat = (r'(?P<indent>^[ \t]*)(?P<cond>%if [^\n]*with_' + flag + r'plugin[^\n]*)\n'
           r'(?P<body>[^\n]*--with-' + flag + r'[^\n]*\n)'
           r'(?P=indent)%endif\n')
    repl = (r'\g<indent>\g<cond>\n'
            r'\g<body>'
            r'\g<indent>%else\n'
            r'\g<indent>CONFIG_ARGS="$CONFIG_ARGS --without-' + flag + r'-plugin"\n'
            r'\g<indent>%endif\n')
    return re.sub(pat, repl, src, flags=re.M)

for _flag in ('clang', 'llvm'):
    s = _add_plugin_else(s, _flag)

# Expand %ldconfig_scriptlets for RPM 4.11
def _ldconfig(m):
    sub = m.group(1)
    if sub:
        return (f'%post -n %{{name}}-{sub} -p /sbin/ldconfig\n'
                f'%postun -n %{{name}}-{sub} -p /sbin/ldconfig')
    return '%post -p /sbin/ldconfig\n%postun -p /sbin/ldconfig'
s = re.sub(r'^%ldconfig_scriptlets(?:\s+(\S+))?\s*$', _ldconfig, s, flags=re.M)

# Comment out rich / weak dependencies unsupported in RPM 4.11
s = re.sub(r'^(Recommends|Suggests|Supplements|Enhances):', r'# &', s, flags=re.M)
s = re.sub(r'^(Requires|BuildRequires|Conflicts|Provides|Obsoletes):\s*\(.*\)\s*$',
           r'# &', s, flags=re.M)
s = re.sub(r'^Requires\(', r'# Requires(', s, flags=re.M)

# Normalize %patch invocation for RPM 4.11 (numeric index only)
def _patch_names(m):
    name = m.group('name')
    rest = m.group('rest') or ''
    if name.startswith('-P') or name.startswith('-'):
        return m.group(0)
    if name.isdigit():
        return f'%patch -P{int(name)} {rest}'.rstrip()
    if name not in _patch_names.seen:
        _patch_names.seen[name] = len(_patch_names.seen)
    return f'%patch -P{_patch_names.seen[name]} {rest}'.rstrip()


_patch_names.seen = {}
s = re.sub(r'^%patch\s+(?P<name>\S+)(?P<rest>\s+-p\d+)?\s*$', _patch_names, s, flags=re.M)

def _patch_tag(m):
    return f'{m.group("pfx")}{int(m.group("num"))}:'
s = re.sub(r'^(?P<pfx>Patch)(?P<num>0\d+)\s*:', _patch_tag, s, flags=re.M)

if _patch_names.seen:
    tags = ''.join(f'Patch{n}: {name}\n' for name, n in _patch_names.seen.items())
    anchor = re.search(r'^\s*%(?:description|prep|package|build)\b', s, re.M)
    if anchor:
        s = s[:anchor.start()] + tags + s[anchor.start():]

s = re.sub(r'^%global have_libipt 1$', '%global have_libipt 0', s, flags=re.M)
s = re.sub(r'--with-debuginfod\b', '--without-debuginfod', s)
s = s.replace('{gdb,annotate}{.info,/index.html,.pdf}', '{gdb,annotate}{.info,/index.html}')
s = re.sub(r'--with-system-readline\b', '--without-system-readline', s)
s = re.sub(r'^\s*mv -f readline/readline/doc readline-doc\n'
           r'\s*rm -rf readline/readline/\*\n'
           r'\s*mv -f readline-doc readline/readline/doc\n',
           '# bundled readline kept for EL7\n', s, flags=re.M)

s = re.sub(r'^%global ANNOBIN_GCC_PLUGIN_DIR .*$',
           '%global ANNOBIN_GCC_PLUGIN_DIR /usr/lib/gcc/x86_64-redhat-linux/4.8.5/plugin',
           s, flags=re.M)
s = re.sub(r'^%global gcc_vr .*$', '%global gcc_vr 4.8.5-44.el7', s, flags=re.M)

s = re.sub(r'^%bcond_without plugin_rebuild$', '%bcond_with plugin_rebuild',
           s, flags=re.M)

def _disable_jupyter(src):
    m = re.search(r'^%files jupyter\b.*?(?=^(?:%files|%changelog)\b)',
                  src, flags=re.M | re.S)
    if m:
        src = (src[:m.start()] + '%if 0%{?rhel} > 7\n'
               + m.group(0).rstrip('\n') + '\n%endif\n' + src[m.end():])
    for sec in ('%package jupyter', '%description jupyter'):
        m = re.search(r'^' + re.escape(sec) + r'\s*\n(?:.*?\n)*?(?=^(?:%|\s*$))',
                      src, flags=re.M)
        if m:
            src = (src[:m.start()] + '%if 0%{?rhel} > 7\n'
                   + m.group(0).rstrip('\n') + '\n%endif\n' + src[m.end():])
    return src

# Rewrite %py_byte_compile for EL7
s = s.replace('%py_byte_compile %{python3} ', '%py_byte_compile %{__python3} ')

s = _disable_jupyter(s)

_HAVE_SPHINX = '0'
for _p in ('/usr/bin/sphinx-build', '/usr/local/bin/sphinx-build', '/bin/sphinx-build'):
    if os.path.exists(_p):
        _HAVE_SPHINX = '1'
        break

s = re.sub(r'^(%global\s+gcc_major\s+\d+.*)$',
           r'\1\n%global have_sphinx ' + _HAVE_SPHINX,
           s, count=1, flags=re.M)

s = re.sub(
    r'^(?P<i>[ \t]*)make jit\.sphinx\.html\n'
    r'(?P=i)make jit\.sphinx\.install-html jit_htmldir=`pwd`/\.\./\.\./rpm\.doc/libgccjit-devel/html\n',
    lambda m: (f"{m.group('i')}%if %{{have_sphinx}}\n"
               f"{m.group('i')}make jit.sphinx.html\n"
               f"{m.group('i')}make jit.sphinx.install-html jit_htmldir=`pwd`/../../rpm.doc/libgccjit-devel/html\n"
               f"{m.group('i')}%else\n"
               f"{m.group('i')}mkdir -p ../../rpm.doc/libgccjit-devel/html\n"
               f"{m.group('i')}echo 'libgccjit HTML docs require Sphinx (skipped on CentOS 7).' \\\n"
               f"{m.group('i')}  > ../../rpm.doc/libgccjit-devel/html/README.txt\n"
               f"{m.group('i')}%endif\n"),
    s, flags=re.M)
_GCC_PKG_GUARDS = (
    (re.compile(r'^%(?:package|files)\s+-n\s+.*sysroot_package_arch'), 'build_cross'),
    (re.compile(r'^%package offload-nvptx\b'), 'build_offload_nvptx'),
    (re.compile(r'^%package offload-amdgcn\b'), 'build_offload_amdgcn'),
    (re.compile(r'^%package plugin-annobin\b'), 'build_annobin_plugin'),
    (re.compile(r'^%package\s+-n\s+.*cross-gcc-'), 'build_cross'),
)


def _guard_gcc_subpkgs(text):
    lines = text.split('\n')
    out = []
    i = 0
    n = len(lines)
    top_re = re.compile(r'^%(package|files|prep|build|install|check|'
                        r'changelog|clean|post|postun|pre|preun|verifyscript|trigger)\b')
    while i < n:
        flag = None
        for rx, f in _GCC_PKG_GUARDS:
            if rx.match(lines[i]):
                flag = f
                break
        if flag is None:
            out.append(lines[i])
            i += 1
            continue
        is_files = lines[i].startswith('%files')
        block = [lines[i]]
        i += 1
        if is_files:
            while i < n and not top_re.match(lines[i]):
                block.append(lines[i])
                i += 1
        else:
            while i < n:
                ln = lines[i]
                if top_re.match(ln):
                    if re.match(r'^%description\b', ln):
                        block.append(ln)
                        i += 1
                        while i < n and not top_re.match(lines[i]):
                            block.append(lines[i])
                            i += 1
                    break
                block.append(ln)
                i += 1
        out.append('%if %{' + flag + '}')
        out.extend(block)
        out.append('%endif')
    return '\n'.join(out)


s = _guard_gcc_subpkgs(s)

# multilib: EL7 build has multilib disabled (--disable-multilib)
s = re.sub(r'^(%global\s+gcc_major\s+\d+.*)$',
           r'\1\n%global build_multilib 0',
           s, count=1, flags=re.M)
s = re.sub(r'^%ifarch %\{multilib_64_archs\}$',
           '%if %{build_multilib}', s, flags=re.M)

# find-lang fallback
s = re.sub(r'^%find_lang cpplib$', '%find_lang cpplib || true\n: > cpplib.lang',
           s, flags=re.M)
s = re.sub(r'^%find_lang %\{name\}$',
           '%find_lang %{name} || true\n: > %{name}.lang', s, flags=re.M)

# Guard libgccjit-devel %doc entries requiring Sphinx
s = re.sub(
    r'^(%doc rpm\.doc/libgccjit-devel/\*\n%doc gcc/jit/docs/examples)$',
    r'%if %{have_sphinx}\n\1\n%endif', s, flags=re.M)

# Guard tmpfiles configuration with with_sysusers
s = re.sub(r'^(%\{_tmpfilesdir\}/systemtap-server\.conf)$',
           lambda m: '%if %{with_sysusers}\n' + m.group(1) + '\n%endif',
           s, flags=re.M)

# Normalize changelog dates for RPM 4.11 (Day Mon DD YYYY)
_DAY_FIX = {'Thr': 'Thu', 'Tues': 'Tue', 'Weds': 'Wed', 'Thur': 'Thu', 'Thurs': 'Thu',
            'Sund': 'Sun', 'Mond': 'Mon'}
def _changelog_day(m):
    d = _DAY_FIX.get(m.group('d'), m.group('d'))
    return f'* {d} {m.group("rest")}'
s = re.sub(r'^\* (?P<d>[A-Za-z]{3,5}) (?P<rest>[A-Z][a-z]{2} .*)$', _changelog_day, s, flags=re.M)
s = re.sub(
    r'^\* (?P<d>[A-Za-z]{3,5}) (?P<mon>[A-Z][a-z]{2}) (?P<day>\d{1,2}) '
    r'(?:\d{2}:\d{2}:\d{2} )?(?:[A-Z]{2,5} )?(?P<year>\d{4})',
    lambda m: f'* {m.group("d")} {m.group("mon")} {m.group("day")} {m.group("year")}',
    s, flags=re.M)

_MON = {m: i + 1 for i, m in enumerate(
    ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])}
def _changelog_weekday(m):
    d, mon, day, year = m.group('d'), m.group('mon'), m.group('day'), m.group('year')
    try:
        import datetime
        dt = datetime.date(int(year), _MON[mon], int(day))
    except (KeyError, ValueError):
        return m.group(0)
    real = dt.strftime('%a')
    if d == real:
        return m.group(0)
    return f'* {real} {mon} {day} {year}'
s = re.sub(
    r'^\* (?P<d>[A-Za-z]{3,5}) (?P<mon>[A-Z][a-z]{2}) +(?P<day>\d{1,2}) +(?P<year>\d{4})',
    _changelog_weekday, s, flags=re.M)

if s != orig:
    open(path, 'w', encoding='utf-8').write(s)
