# devtoolset-14 (GCC 14.3.1 for CentOS 7 / RHEL 7)

A Software Collection (SCL) packaging of the GCC 14 toolchain for CentOS 7 and RHEL 7 (x86_64).

Upstream component versions and patches are aligned with the **Rocky Linux 10 (EL10)** baseline and backported to run under CentOS 7's RPM 4.11 and glibc 2.17 environment.

- **Target Platform**: CentOS 7 / RHEL 7 (x86_64)
- **SCL Name**: `devtoolset-14`
- **Installation Root**: `/opt/rh/devtoolset-14/root`
- **Environment Entry**: `scl enable devtoolset-14 bash`
- **Deliverables**: Binary RPMs, Source RPMs (SRPMs), and standalone release tarball

---

## Component Matrix

Component versions match the EL10 distribution packages:

| Component | Version | Upstream Repo | Package Name |
|---|---|---|---|
| GCC (C, C++, Fortran) | 14.3.1 | BaseOS | `devtoolset-14-gcc` |
| Binutils | 2.41 | BaseOS | `devtoolset-14-binutils` |
| Make | 4.4.1 | BaseOS | `devtoolset-14-make` |
| Elfutils | 0.194 | BaseOS | `devtoolset-14-elfutils` |
| Strace | 6.12 | BaseOS | `devtoolset-14-strace` |
| Annobin | 13.02 | AppStream | `devtoolset-14-annobin` |
| DWZ | 0.16 | AppStream | `devtoolset-14-dwz` |
| Dyninst | 13.0.0 | AppStream | `devtoolset-14-dyninst` |
| GDB | 16.3 | AppStream | `devtoolset-14-gdb` |
| Ltrace | 0.7.91 | AppStream | `devtoolset-14-ltrace` |
| SystemTap | 5.4 | AppStream | `devtoolset-14-systemtap` |
| Valgrind | 3.26.0 | AppStream | `devtoolset-14-valgrind` |
| Metapackages | 14.1 | N/A | `devtoolset-14` |

*Note*: `oprofile` and `memstomp` were deprecated and removed upstream in EL10, so they are omitted here.

For exact upstream SRPM hashes and Koji builds, see [EL10-BASELINE.md](devtoolset-14/releng/EL10-BASELINE.md). Component download URLs and source SHA512 checksums are tracked in [pins.env](devtoolset-14/releng/pins.env).

---

## Installation & Usage

### Setting Up the Repository

Configure the YUM repository:

```bash
curl -o /etc/yum.repos.d/devtoolset-el7.repo https://el7.cooluc.com/devtoolset-el7.repo
```

### Installing Packages

Install core toolchain components:

```bash
yum install -y devtoolset-14-gcc devtoolset-14-gcc-c++ devtoolset-14-make
```

Or install the full suite via the metapackage:

```bash
yum install -y devtoolset-14
```

*(Standalone RPM tarballs and individual RPMs are also published under GitHub Releases for offline environments.)*

### Enabling the Toolchain

Enable devtoolset-14 in your current shell:

```bash
scl enable devtoolset-14 bash
```

Verify compiler version:

```bash
gcc --version
# gcc (GCC) 14.3.1 20250212 (Red Hat 14.3.1-4)
```

Alternatively, source the environment file directly:

```bash
source /opt/rh/devtoolset-14/enable
```

---

## Repository Structure

```
.
├── .ci/
│   └── Dockerfile.dts14        # CentOS 7 build container definition
├── .github/
│   └── workflows/
│       └── build.yml           # GitHub Actions CI/CD workflow
└── devtoolset-14/
    ├── releng/                 # Release engineering scripts and tools
    │   ├── ci-common.sh        # Shared environment setup and spec patchers
    │   ├── ci-release.sh       # Full release orchestration script
    │   ├── el7-compat.py       # Spec compatibility filter for RPM 4.11
    │   ├── scl-wire.py         # SCL macro injector for EL10 specs
    │   ├── pins.env            # Upstream source URLs and SHA512 pins
    │   └── EL10-BASELINE.md    # EL10 SRPM baseline provenance
    └── specs/                  # Package specifications and patches
        ├── <comp>-el10/        # Backported EL10 specs, patches, sources
        ├── automake-el7/       # Automake 1.16 build-time helper
        └── meta/               # devtoolset-14 metapackages
```

---

## Building

### Building with GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/build.yml`):

1. **Tag Trigger**: Pushing a tag matching `v*` (e.g., `v14.3.1`) triggers a complete toolchain build, packages `devtoolset-14-<tag>-rpms.tar.gz`, calculates SHA-256 sums, and publishes a new GitHub Release.
2. **Manual Trigger (`workflow_dispatch`)**:
   - `target`: `release` (full build), `deps` (all dependencies), `gcc` (GCC only), `component` (single component), or `meta` (metapackages).
   - `component`: Name of the component to build when target is set to `component`.
   - `publish_release`: Boolean flag to publish artifacts to GitHub Releases.

### Building Locally with Docker

Prerequisites: Docker with access to CentOS 7 mirror repositories.

```bash
# 1. Build the CentOS 7 builder container
docker build -t dts14-builder -f .ci/Dockerfile.dts14 .ci

# 2. Build the full toolchain and release archive
docker run --rm \
  -v "$PWD:/workspace" \
  -v "$PWD/out:/out" \
  -e RELEASE_TAG=14.3.1 \
  dts14-builder bash /workspace/devtoolset-14/releng/ci-release.sh

# 3. Build a specific component (e.g. make)
docker run --rm \
  -v "$PWD:/workspace" \
  -v "$PWD/out:/out" \
  -e COMPS="make" \
  -e RELEASE=0 \
  dts14-builder bash /workspace/devtoolset-14/releng/ci-release.sh
```

Built RPMs are placed in `out/rpms/`, SRPMs in `out/srpms/`, and build logs in `out/logs/`.

---

## Technical Notes & Implementation Details

1. **Bootstrap Compiler**: Stock CentOS 7 provides GCC 4.8.5, which cannot compile GCC 14 (requires C++17 host compiler). The build container bootstraps using `devtoolset-12` (GCC 12) from EPEL 7 / Copr.
2. **RPM 4.11 Compatibility**: Upstream EL10 specs utilize modern RPM 4.19+ constructs (`%autochangelog`, `%autorelease`, `%patch -P`, `%patchN`, boolean dependency syntax, and `<lua>` scriptlets). `el7-compat.py` and `macros.el7-compat` rewrite these constructs into forms compatible with RPM 4.11.
3. **SCL Namespace Injection**: `scl-wire.py` prefixes packages with `devtoolset-14-`, injects `%scl_package` macros, adjusts install prefixes to `/opt/rh/devtoolset-14/root`, and sets up alternative file paths.
4. **Glibc 2.17 Compatibility**: Modern components expecting glibc >= 2.28 features have compatibility shims applied (e.g. `dyninst-elf-compat.h` for missing ELF header definitions; boost header overlays for dyninst C++17 requirements).
5. **Single-Stage Build**: GCC 14 is built with `--disable-bootstrap` using the devtoolset-12 host compiler to keep compilation within CI timeouts while generating production-quality binaries.
