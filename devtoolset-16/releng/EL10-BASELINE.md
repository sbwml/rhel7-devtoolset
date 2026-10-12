# devtoolset-16 Baseline: CentOS Stream 10 (EL10)

Component versions are aligned with the **CentOS Stream 10 (EL10)** distribution, using upstream source RPMs as the reference baseline.

Upstream repository mirror: `http://mirror.stream.centos.org/10-stream/AppStream/source/tree/Packages/`

| Component | Upstream SRPM | Version | Repository |
|---|---|---|---|
| gcc / gcc-c++ / gcc-gfortran | `gcc-toolset-16-gcc-16.2.1-1.2.el10.src.rpm` | 16.2.1 | AppStream |
| binutils | `gcc-toolset-16-binutils-2.46-3.el10.src.rpm` | 2.46 | AppStream |
| meta | `gcc-toolset-16-16.0-1.el10.src.rpm` | 16.0 | AppStream |

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
