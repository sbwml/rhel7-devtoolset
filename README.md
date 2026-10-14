# Red Hat Developer Toolset for CentOS 7 / RHEL 7

Software Collection (SCL) packaging of modern GCC toolchains for CentOS 7 and RHEL 7 (x86_64).

This repository provides backports for:
- **devtoolset-16**: GCC 16.2.1 toolchain and complete userland diagnostics suite, based on **CentOS Stream 10 (EL10)** `gcc-toolset-16` and EL10 baseline.
- **devtoolset-14**: GCC 14.3.1 toolchain and complete userland diagnostics suite, based on **Rocky Linux 10 (EL10)**.

Both toolsets are packaged to run under CentOS 7's RPM 4.11 and glibc 2.17 runtime environment.

---

## Toolset Overview

| Feature | devtoolset-16 | devtoolset-14 |
|---|---|---|
| **GCC Version** | 16.2.1 | 14.3.1 |
| **Binutils Version** | 2.46 | 2.41 |
| **Upstream Baseline** | CentOS Stream 10 (`gcc-toolset-16`) | Rocky Linux 10 (`gcc-14`) |
| **SCL Name** | `devtoolset-16` | `devtoolset-14` |
| **Installation Root** | `/opt/rh/devtoolset-16/root` | `/opt/rh/devtoolset-14/root` |
| **Environment Entry** | `scl enable devtoolset-16 bash` | `scl enable devtoolset-14 bash` |
| **Bootstrap Compiler**| `devtoolset-12` | `devtoolset-12` |

---

## Component Matrix

### devtoolset-16 (EL10 Baseline)

| Component | Version | Upstream SRPM | Package Name |
|---|---|---|---|
| GCC (C, C++, Fortran) | 16.2.1 | `gcc-toolset-16-gcc-16.2.1-1.2.el10.src.rpm` | `devtoolset-16-gcc` |
| Binutils | 2.46 | `gcc-toolset-16-binutils-2.46-3.el10.src.rpm` | `devtoolset-16-binutils` |
| Make | 4.4.1 | `make-4.4.1-9.el10.src.rpm` | `devtoolset-16-make` |
| Autoconf | 2.71 | `autoconf-2.71-13.el10.src.rpm` | `devtoolset-16-autoconf` |
| Automake | 1.16.1 | `automake-1.16.1-8.el8.src.rpm` | `devtoolset-16-automake` |
| CMake | 3.31.8 | `cmake-3.31.8-1.el10.src.rpm` | `devtoolset-16-cmake` |
| Elfutils | 0.194 | `elfutils-0.194-2.el10.rocky.0.1.src.rpm` | `devtoolset-16-elfutils` |
| Strace | 6.12 | `strace-6.12-3.el10.src.rpm` | `devtoolset-16-strace` |
| Annobin | 13.02 | `annobin-13.02-2.el10.src.rpm` | `devtoolset-16-annobin` |
| DWZ | 0.16 | `dwz-0.16-1.el10.src.rpm` | `devtoolset-16-dwz` |
| Dyninst | 13.0.0 | `dyninst-13.0.0-1.el10.src.rpm` | `devtoolset-16-dyninst` |
| GDB | 16.3 | `gdb-16.3-3.el10.src.rpm` | `devtoolset-16-gdb` |
| Ltrace | 0.7.91 | `ltrace-0.7.91-53.el10.src.rpm` | `devtoolset-16-ltrace` |
| SystemTap | 5.4 | `systemtap-5.4-3.el10.src.rpm` | `devtoolset-16-systemtap` |
| Valgrind | 3.26.0 | `valgrind-3.26.0-5.el10.src.rpm` | `devtoolset-16-valgrind` |
| xxHash (Prerequisite) | 0.8.2 | `xxhash-0.8.2-11.el10.src.rpm` | `xxhash` |
| Babeltrace (Prerequisite) | 1.5.11 | `babeltrace-1.5.11-8.el10.src.rpm` | `babeltrace` |
| Boost 1.83 (Prerequisite) | 1.83.0 | `boost183-1.83.0-8.el10.src.rpm` | `boost183` |
| Metapackages | 16.0 | `gcc-toolset-16-16.0-1.el10.src.rpm` | `devtoolset-16` |

For exact upstream SRPM hashes and Koji builds, see [EL10-BASELINE.md](devtoolset-16/releng/EL10-BASELINE.md).

### devtoolset-14 (EL10 Baseline)

| Component | Version | Upstream SRPM | Package Name |
|---|---|---|---|
| GCC (C, C++, Fortran) | 14.3.1 | `gcc-14.3.1-4.4.el10.src.rpm` | `devtoolset-14-gcc` |
| Binutils | 2.41 | `binutils-2.41-63.el10.src.rpm` | `devtoolset-14-binutils` |
| Make | 4.4.1 | `make-4.4.1-9.el10.src.rpm` | `devtoolset-14-make` |
| Autoconf | 2.71 | `autoconf-2.71-13.el10.src.rpm` | `devtoolset-14-autoconf` |
| Automake | 1.16.1 | `automake-1.16.1-8.el8.src.rpm` | `devtoolset-14-automake` |
| CMake | 3.31.8 | `cmake-3.31.8-1.el10.src.rpm` | `devtoolset-14-cmake` |
| Elfutils | 0.194 | `elfutils-0.194-2.el10.rocky.0.1.src.rpm` | `devtoolset-14-elfutils` |
| Strace | 6.12 | `strace-6.12-3.el10.src.rpm` | `devtoolset-14-strace` |
| Annobin | 13.02 | `annobin-13.02-2.el10.src.rpm` | `devtoolset-14-annobin` |
| DWZ | 0.16 | `dwz-0.16-1.el10.src.rpm` | `devtoolset-14-dwz` |
| Dyninst | 13.0.0 | `dyninst-13.0.0-1.el10.src.rpm` | `devtoolset-14-dyninst` |
| GDB | 16.3 | `gdb-16.3-3.el10.src.rpm` | `devtoolset-14-gdb` |
| Ltrace | 0.7.91 | `ltrace-0.7.91-53.el10.src.rpm` | `devtoolset-14-ltrace` |
| SystemTap | 5.4 | `systemtap-5.4-3.el10.src.rpm` | `devtoolset-14-systemtap` |
| Valgrind | 3.26.0 | `valgrind-3.26.0-5.el10.src.rpm` | `devtoolset-14-valgrind` |
| xxHash (Prerequisite) | 0.8.2 | `xxhash-0.8.2-11.el10.src.rpm` | `xxhash` |
| Babeltrace (Prerequisite) | 1.5.11 | `babeltrace-1.5.11-8.el10.src.rpm` | `babeltrace` |
| Boost 1.83 (Prerequisite) | 1.83.0 | `boost183-1.83.0-8.el10.src.rpm` | `boost183` |
| Metapackages | 14.1 | N/A | `devtoolset-14` |

For exact upstream SRPM hashes and Koji builds, see [EL10-BASELINE.md](devtoolset-14/releng/EL10-BASELINE.md).

---

## Installation & Usage

### Setting Up the Repository

Configure the YUM repository on CentOS 7 / RHEL 7:

```bash
curl -o /etc/yum.repos.d/devtoolset-el7.repo https://el7.cooluc.com/devtoolset-el7.repo
```

### Installing devtoolset-16

Install the complete suite via the metapackage:

```bash
yum install -y devtoolset-16
```

Or install core toolchain packages individually:

```bash
yum install -y devtoolset-16-gcc devtoolset-16-gcc-c++ devtoolset-16-binutils devtoolset-16-make
```

#### Enabling devtoolset-16

Enable the collection in your current shell:

```bash
scl enable devtoolset-16 bash
```

Verify compiler version:

```bash
gcc --version
# gcc (GCC) 16.2.1 ...
```

Alternatively, source the environment script directly:

```bash
source /opt/rh/devtoolset-16/enable
```

---

### Installing devtoolset-14

Install the complete suite via the metapackage:

```bash
yum install -y devtoolset-14
```

Or install core toolchain packages:

```bash
yum install -y devtoolset-14-gcc devtoolset-14-gcc-c++ devtoolset-14-make
```

#### Enabling devtoolset-14

Enable the collection in your current shell:

```bash
scl enable devtoolset-14 bash
```

Verify compiler version:

```bash
gcc --version
gcc (GCC) 14.3.1 20251022 (Red Hat 14.3.1-4)
```

Alternatively, source the environment script directly:

```bash
source /opt/rh/devtoolset-14/enable
```

---

## Repository Structure

```
.
├── .ci/
│   └── Dockerfile              # Shared CentOS 7 builder container (devtoolset-12 toolchain)
├── .github/
│   └── workflows/
│       └── build.yml           # GitHub Actions CI/CD workflow (supports DTS 14 & 16)
├── devtoolset-14/              # devtoolset-14 release engineering and specs
│   ├── releng/
│   └── specs/
└── devtoolset-16/              # devtoolset-16 release engineering and specs
    ├── releng/
    │   ├── ci-common.sh        # Shared environment setup using devtoolset-12 host
    │   ├── ci-release.sh       # Release orchestration script
    │   ├── el7-compat.py       # Spec compatibility filter for RPM 4.11
    │   ├── scl-wire.py         # SCL macro injector
    │   ├── pins.env            # Upstream source tracking
    │   └── EL10-BASELINE.md    # EL10 SRPM baseline provenance
    └── specs/
        ├── binutils-el10/      # Binutils 2.46 spec and patches
        ├── gcc-el10/           # GCC 16.2.1 spec and patches
        ├── meta/               # devtoolset-16 metapackages
        └── ...                 # Full diagnostic & build tools (make, gdb, elfutils, strace, etc.)
```

---

## Building

### Building with GitHub Actions

The GitHub Actions workflow (`.github/workflows/build.yml`) supports building both versions:

1. **Tag Trigger**:
   - Pushing tags matching `v16*` (e.g. `v16.2.1`) triggers the `devtoolset-16` build and release.
   - Pushing tags matching `v14*` (e.g. `v14.3.1`) triggers the `devtoolset-14` build and release.
2. **Manual Trigger (`workflow_dispatch`)**:
   - `version`: Choose `16` or `14` (default `16`).
   - `target`: `release` (full toolchain), `deps` (dependencies), `gcc` (GCC only), `component` (single component), or `meta` (metapackages).
   - `component`: Name of the component when target is set to `component`.
   - `publish_release`: Boolean flag to publish artifacts to GitHub Releases.

### Building Locally with Docker

Prerequisites: Docker with access to CentOS 7 mirror repositories.

```bash
# 1. Build the shared builder image (devtoolset-12 toolchain)
docker build -t dts-builder -f .ci/Dockerfile .ci

# 2. Build devtoolset-16
docker run --rm \
  -v "$PWD:/workspace" \
  -v "$PWD/out:/out" \
  -e RELEASE_TAG=16.2.1 \
  dts-builder bash /workspace/devtoolset-16/releng/ci-release.sh

# Or build devtoolset-14
docker run --rm \
  -v "$PWD:/workspace" \
  -v "$PWD/out:/out" \
  -e RELEASE_TAG=14.3.1 \
  dts-builder bash /workspace/devtoolset-14/releng/ci-release.sh
```

---

## Technical Notes

1. **Bootstrap Toolchain**:
   - GCC 16 and GCC 14 utilize `devtoolset-12` (GCC 12) as the host bootstrap compiler.
2. **Single-Stage Build**:
   - GCC 16 builds with `--disable-bootstrap` under the verified `devtoolset-12` host compiler to fit execution within CI timeouts.
3. **RPM 4.11 Compatibility**:
   - Upstream EL10 specs utilize RPM 4.19+ constructs (`%autochangelog`, `%autorelease`, `%patch -P`, `%patchN`, boolean dependency syntax). `el7-compat.py` and `macros.el7-compat` rewrite these constructs into forms compatible with RPM 4.11.
4. **SCL Isolation**:
   - All files are installed under `/opt/rh/devtoolset-16/root`. Sanitizer runtime libraries and GCC support libraries are strictly contained within SCL library directories.
