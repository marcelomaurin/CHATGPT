#ifndef MP_POSE_BRIDGE_H
#define MP_POSE_BRIDGE_H
#include <stdint.h>

#if defined(_WIN32)
  #define MP_POSE_CALL __cdecl
  #ifdef MP_POSE_BUILD
    #define MP_POSE_API __declspec(dllexport)
  #else
    #define MP_POSE_API __declspec(dllimport)
  #endif
#else
  #define MP_POSE_CALL
  #define MP_POSE_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define MP_POSE_ABI_VERSION    1
#define MP_POSE_LANDMARK_COUNT 33

/* Error codes */
#define MP_OK                  0
#define MP_ERR_ABI_MISMATCH    1
#define MP_ERR_BAD_ARG         2
#define MP_ERR_MODEL_LOAD      3
#define MP_ERR_NOT_INITIALIZED 4
#define MP_ERR_INFERENCE       5
#define MP_ERR_UNSUPPORTED     6
#define MP_ERR_OUT_OF_MEMORY   7
#define MP_ERR_BACKEND         8

typedef void* mp_pose_handle;

/*
 * mp_pose_info
 * All fields are written only up to client_struct_size, preventing overflow
 * when an older caller passes a smaller struct.
 * ABI remains v1 (pre-release) while backend field is present.
 */
typedef struct {
  int32_t struct_size;
  int32_t abi_version;            /* == MP_POSE_ABI_VERSION */
  char    bridge_version[32];     /* e.g. "1.0.0" */
  char    mediapipe_version[32];  /* e.g. "0.10.35" */
  char    platform[16];           /* "windows" | "linux" */
  char    arch[16];               /* "x86_64" */
  char    model_name[128];        /* Loaded .task model name */
  char    backend[16];            /* "SIM" | "REAL" — appended in v1 pre-release */
} mp_pose_info;

typedef struct {
  int32_t     struct_size;
  const char* model_path;             /* Absolute path to .task model file (REAL only) */
  int32_t     running_mode;           /* 0 = IMAGE, 1 = VIDEO */
  int32_t     num_poses;              /* Max poses to detect, >= 1 */
  float       min_pose_detection_confidence;
  float       min_pose_presence_confidence;
  float       min_tracking_confidence;
  int32_t     output_segmentation_mask; /* 0 | 1 */
  int32_t     num_threads;            /* 0 = automatic */
} mp_pose_config;

/*
 * mp_image_raw
 * Represents raw input image buffer.
 * Data MUST be in packed RGB format (3 or 4 channels).
 * stride must satisfy: stride >= width * channels.
 */
typedef struct {
  int32_t        struct_size;
  const uint8_t* data;
  int32_t        width;
  int32_t        height;
  int32_t        channels;             /* 3 for RGB, 4 for RGBA */
  int32_t        stride;               /* Row width in bytes */
  int64_t        timestamp_ms;         /* VIDEO mode: monotonically increasing */
} mp_image_raw;

/*
 * mp_landmark
 * Normalized landmark coordinates in image space.
 * x, y: normalized values in the range [0.0, 1.0].
 * z: relative depth.
 */
typedef struct {
  float x;
  float y;
  float z;
  float visibility;
  float presence;
} mp_landmark;

/*
 * mp_world_landmark
 * World 3D coordinates in meters.
 */
typedef struct {
  float x;
  float y;
  float z;
} mp_world_landmark;

/*
 * mp_pose_result
 * POD struct — allocated/freed with malloc/free by the DLL.
 * Never mix with new/delete on either side.
 */
typedef struct {
  int32_t            struct_size;
  int32_t            pose_count;
  int32_t            landmarks_per_pose;   /* == 33 */
  mp_landmark*       landmarks;            /* Array of pose_count * 33 elements */
  mp_world_landmark* world_landmarks;      /* Array of pose_count * 33 elements */
  int32_t            mask_present;         /* 0 | 1 */
  int32_t            mask_width;
  int32_t            mask_height;
  const uint8_t*     mask;                 /* mask_width * mask_height bytes or NULL */
} mp_pose_result;

/* Metadata — safe to query before creating an instance */
MP_POSE_API int32_t MP_POSE_CALL mp_pose_get_info(mp_pose_info* out_info);

/* Lifecycle */
MP_POSE_API int32_t MP_POSE_CALL mp_pose_create(const mp_pose_config* cfg, mp_pose_handle* out_handle);
MP_POSE_API void    MP_POSE_CALL mp_pose_destroy(mp_pose_handle h);

/* Inference: RGB/RGBA packed image; result allocated by the DLL */
MP_POSE_API int32_t MP_POSE_CALL mp_pose_detect(mp_pose_handle h, const mp_image_raw* img, mp_pose_result** out_result);
/* Double-pointer free: sets *result to NULL after releasing */
MP_POSE_API void    MP_POSE_CALL mp_pose_free_result(mp_pose_result** result);

/* UTF-8 last error string (pass NULL for global/init errors) */
MP_POSE_API const char* MP_POSE_CALL mp_pose_last_error(mp_pose_handle h);

#ifdef __cplusplus
}
#endif
#endif /* MP_POSE_BRIDGE_H */
