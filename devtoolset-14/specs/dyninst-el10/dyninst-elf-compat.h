/* devtoolset-14: Compatibility constants missing from CentOS 7 (glibc 2.17) <elf.h>
 * needed by dyninst 13 (EM_AMDGPU, DF_1_PIE, R_X86_64_REX_GOTPCRELX).
 */
#ifndef DYNINST_EL7_ELF_COMPAT_H
#define DYNINST_EL7_ELF_COMPAT_H

#include <elf.h>

#ifndef EM_AMDGPU
# define EM_AMDGPU              224     /* AMD GPU */
#endif

#ifndef DF_1_PIE
# define DF_1_PIE               0x08000000
#endif

#ifndef R_X86_64_REX_GOTPCRELX
# define R_X86_64_REX_GOTPCRELX 42      /* Load from GOT, REX prefix allowed */
#endif

#endif /* DYNINST_EL7_ELF_COMPAT_H */
