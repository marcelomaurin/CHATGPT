#include "../include/mp_pose_bridge.h"
#include <string.h>
#include <stddef.h>  /* offsetof */

extern "C" int32_t MP_POSE_CALL mp_pose_get_info(mp_pose_info* out_info) {
  if (!out_info) {
    return MP_ERR_BAD_ARG;
  }

  /* Save the client's declared struct size before zeroing */
  int32_t client_struct_size = out_info->struct_size;
  if (client_struct_size <= 0) {
    return MP_ERR_BAD_ARG;
  }

  /* Zero only as much as the client declared, preventing over-write */
  int32_t bytes_to_zero = (client_struct_size < (int32_t)sizeof(mp_pose_info))
                          ? client_struct_size
                          : (int32_t)sizeof(mp_pose_info);

  memset(out_info, 0, bytes_to_zero);

  /* Write our actual size so the caller knows the DLL layout */
  out_info->struct_size = sizeof(mp_pose_info);
  out_info->abi_version = MP_POSE_ABI_VERSION;

  strncpy(out_info->bridge_version,    "1.0.0",   sizeof(out_info->bridge_version)    - 1);
  strncpy(out_info->mediapipe_version, "0.10.35", sizeof(out_info->mediapipe_version) - 1);

#if defined(_WIN32)
  strncpy(out_info->platform, "windows", sizeof(out_info->platform) - 1);
#elif defined(__linux__)
  strncpy(out_info->platform, "linux",   sizeof(out_info->platform) - 1);
#else
  strncpy(out_info->platform, "unknown", sizeof(out_info->platform) - 1);
#endif

#if defined(_M_X64) || defined(__x86_64__)
  strncpy(out_info->arch, "x86_64",  sizeof(out_info->arch) - 1);
#else
  strncpy(out_info->arch, "unknown", sizeof(out_info->arch) - 1);
#endif

  /* model_name is empty until an active session loads a model */
  out_info->model_name[0] = '\0';

  /*
   * Write backend field only if the caller's struct is large enough to hold it.
   * This protects callers compiled against an older header that lacked backend.
   */
  if (client_struct_size >=
      (int32_t)(offsetof(mp_pose_info, backend) + (int32_t)sizeof(out_info->backend))) {
#ifdef MP_BRIDGE_BACKEND_REAL
    strncpy(out_info->backend, "REAL", sizeof(out_info->backend) - 1);
#else
    strncpy(out_info->backend, "SIM",  sizeof(out_info->backend) - 1);
#endif
  }

  return MP_OK;
}
