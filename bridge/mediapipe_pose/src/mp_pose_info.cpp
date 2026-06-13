#include "../include/mp_pose_bridge.h"
#include <string.h>

extern "C" int32_t MP_POSE_CALL mp_pose_get_info(mp_pose_info* out_info) {
  if (!out_info) {
    return MP_ERR_BAD_ARG;
  }

  // Ensure that the structure size is valid
  int32_t client_struct_size = out_info->struct_size;
  if (client_struct_size <= 0) {
    return MP_ERR_BAD_ARG;
  }

  // Zero out up to the size of the structure passed by the client
  int32_t bytes_to_zero = (client_struct_size < (int32_t)sizeof(mp_pose_info)) 
                          ? client_struct_size 
                          : (int32_t)sizeof(mp_pose_info);
  
  memset(out_info, 0, bytes_to_zero);
  
  // Set sizes and versioning info
  out_info->struct_size = sizeof(mp_pose_info);
  out_info->abi_version = MP_POSE_ABI_VERSION;

  // Set version strings safely
  strncpy(out_info->bridge_version, "1.0.0", sizeof(out_info->bridge_version) - 1);
  strncpy(out_info->mediapipe_version, "0.10.35", sizeof(out_info->mediapipe_version) - 1);

  // Set platform string
#if defined(_WIN32)
  strncpy(out_info->platform, "windows", sizeof(out_info->platform) - 1);
#elif defined(__linux__)
  strncpy(out_info->platform, "linux", sizeof(out_info->platform) - 1);
#else
  strncpy(out_info->platform, "unknown", sizeof(out_info->platform) - 1);
#endif

  // Set architecture string (only x86_64 is officially supported)
#if defined(_M_X64) || defined(__x86_64__)
  strncpy(out_info->arch, "x86_64", sizeof(out_info->arch) - 1);
#else
  strncpy(out_info->arch, "unknown", sizeof(out_info->arch) - 1);
#endif

  // model_name is left empty until an active session loads a model
  out_info->model_name[0] = '\0';

  return MP_OK;
}
