# devtoolset-14 Baseline: Rocky Linux 10 (EL10)

Component versions are aligned with the **Rocky Linux 10 (EL10)** distribution, using upstream source RPMs as the reference baseline.

Upstream repository mirror: `https://mirror.sjtu.edu.cn/rocky/10/<repo>/source/tree/Packages/`

| Component | Upstream SRPM | Version | Repository |
|---|---|---|---|
| gcc / gcc-c++ / gcc-gfortran | `gcc-14.3.1-4.4.el10.src.rpm` | 14.3.1 | BaseOS |
| binutils | `binutils-2.41-63.el10.src.rpm` | 2.41 | BaseOS |
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
| meta | N/A | 14.1 | devtoolset-14 |

> Note: `oprofile` and `memstomp` were removed in EL10 upstream and are not delivered in devtoolset-14.

## Porting Architecture

Specifications and patches in `specs/<comp>-el10/` are unpacked directly from EL10 SRPMs. Upstream source tarballs are fetched on demand by `releng/fetch-srcs.sh` and verified against SHA-512 checksums recorded in `sources`.

### SCL Transformation
- `releng/scl-wire.py` injects Software Collection declarations into specs lacking native SCL support:
  `%global scl devtoolset-14`, `%scl_package <pkg>`, and `Name: %{?scl_prefix}...`.
- `gdb` and `valgrind` specs provide built-in SCL conditionals (`%{?scl:%scl_package ...}`) and only require `%scl devtoolset-14` defined in `~/.rpmmacros`.
- Installation root is standardized to `/opt/rh/devtoolset-14/root`.

### CentOS 7 / RPM 4.11 Compatibility
- Strips `%dnl` (introduced in RPM 4.15+).
- Disables rich dependencies (`Requires: (a or b)`) and weak dependencies (`Recommends:`, `Suggests:`).
- Normalizes boolean condition syntax from `%{with X}` to `%{?with_X:1}%{!?with_X:0}`.
- Boost, CMake, and TBB shims satisfy newer toolchain prerequisites under CentOS 7.
- Uses `devtoolset-12` as the bootstrap compiler for GCC 14.
