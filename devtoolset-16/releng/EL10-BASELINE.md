# devtoolset-16 Baseline: CentOS Stream 10 (EL10)

Component versions are aligned with the **CentOS Stream 10 (EL10)** distribution, using upstream source RPMs as the reference baseline.

Upstream repository mirror: `http://mirror.stream.centos.org/10-stream/AppStream/source/tree/Packages/`

| Component | Upstream SRPM | Version | Repository |
|---|---|---|---|
| gcc / gcc-c++ / gcc-gfortran | `gcc-toolset-16-gcc-16.2.1-1.2.el10.src.rpm` | 16.2.1 | AppStream |
| binutils | `gcc-toolset-16-binutils-2.46-3.el10.src.rpm` | 2.46 | AppStream |
| make | `make-4.4.1-9.el10.src.rpm` | 4.4.1 | BaseOS |
| autoconf | `autoconf-2.71-13.el10.src.rpm` | 2.71 | AppStream |
| automake | `automake-1.16.1-8.el8.src.rpm` | 1.16.1 | AppStream |
| elfutils | `elfutils-0.194-2.el10.rocky.0.1.src.rpm` | 0.194 | BaseOS |
| strace | `strace-6.12-3.el10.src.rpm` | 6.12 | BaseOS |
| annobin | `annobin-13.02-2.el10.src.rpm` | 13.02 | AppStream |
| dwz | `dwz-0.16-1.el10.src.rpm` | 0.16 | AppStream |
| dyninst | `dyninst-13.0.0-1.el10.src.rpm` | 13.0.0 | AppStream |
| gdb | `gdb-16.3-3.el10.src.rpm` | 16.3 | AppStream |
| ltrace | `ltrace-0.7.91-53.el10.src.rpm` | 0.7.91 | AppStream |
| systemtap | `systemtap-5.4-3.el10.src.rpm` | 5.4 | AppStream |
| valgrind | `valgrind-3.26.0-5.el10.src.rpm` | 3.26.0 | AppStream |
| xxhash | `xxhash-0.8.2-11.el10.src.rpm` | 0.8.2 | AppStream |
| babeltrace | `babeltrace-1.5.11-8.el10.src.rpm` | 1.5.11 | AppStream |
| boost183 | `boost183-1.83.0-8.el10.src.rpm` | 1.83.0 | AppStream |
| meta | `gcc-toolset-16-16.0-1.el10.src.rpm` | 16.0 | AppStream |

> Note: `oprofile` and `memstomp` were removed in EL10 upstream and are not delivered in devtoolset-16.

## Porting Architecture

Specifications and patches in `specs/<comp>-el10/` and `specs/meta/` are unpacked directly from EL10 SRPMs. Upstream source tarballs are fetched on demand by `releng/fetch-gcc-srcs.sh` and `releng/fetch-srcs.sh` and verified against SHA-512 checksums recorded in `sources`.

### SCL Transformation
- SCL namespace standardized to `devtoolset-16`.
- Package names prefixed with `devtoolset-16-`.
- Installation root is standardized to `/opt/rh/devtoolset-16/root`.
- Environment activation: `scl enable devtoolset-16 bash` or `source /opt/rh/devtoolset-16/enable`.

### CentOS 7 / RPM 4.11 Compatibility
- Strips `%dnl` (introduced in RPM 4.15+).
- Disables rich dependencies (`Requires: (a or b)`) and weak dependencies (`Recommends:`, `Suggests:`).
- Normalizes boolean condition syntax from `%{with X}` to `%{?with_X:1}%{!?with_X:0}`.
- Single-stage build for GCC 16 using `devtoolset-14` as the bootstrap host compiler (`http://el7.cooluc.com/devtoolset-el7.repo`).
