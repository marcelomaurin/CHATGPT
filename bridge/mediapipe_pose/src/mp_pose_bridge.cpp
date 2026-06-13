#include "../include/mp_pose_bridge.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <string>

#ifdef MP_BRIDGE_BACKEND_REAL
#include "mediapipe/tasks/c/vision/pose_landmarker/pose_landmarker_c_api.h"
#endif

// Thread-local error buffer to hold error messages for null handles
#ifdef _MSC_VER
#define THREAD_LOCAL __declspec(thread)
#else
#define THREAD_LOCAL thread_local
#endif

static THREAD_LOCAL std::string g_last_error_msg = "";

struct mp_pose_context {
  mp_pose_config config;
  std::string last_error;
  void* landmarker_instance; // Actual MediaPipe C API instance when MP_BRIDGE_BACKEND_REAL is defined
};

extern "C" {

int32_t MP_POSE_CALL mp_pose_create(const mp_pose_config* cfg, mp_pose_handle* out_handle) {
  if (!cfg || !out_handle) {
    g_last_error_msg = "Null configuration or output handle pointer.";
    return MP_ERR_BAD_ARG;
  }

  if (cfg->struct_size < (int32_t)sizeof(mp_pose_config)) {
    g_last_error_msg = "Invalid mp_pose_config struct size.";
    return MP_ERR_ABI_MISMATCH;
  }

  if (!cfg->model_path || strlen(cfg->model_path) == 0) {
    g_last_error_msg = "Model path cannot be empty.";
    return MP_ERR_MODEL_LOAD;
  }

  mp_pose_context* ctx = (mp_pose_context*)calloc(1, sizeof(mp_pose_context));
  if (!ctx) {
    g_last_error_msg = "Failed to allocate memory for context.";
    return MP_ERR_OUT_OF_MEMORY;
  }

  memcpy(&ctx->config, cfg, sizeof(mp_pose_config));
  ctx->landmarker_instance = nullptr;

#ifdef MP_BRIDGE_BACKEND_REAL
  PoseLandmarkerOptions options = {};
  options.base_options.model_asset_path = cfg->model_path;
  options.running_mode = (cfg->running_mode == 1) ? RunningMode::VIDEO : RunningMode::IMAGE;
  options.num_poses = cfg->num_poses;
  options.min_pose_detection_confidence = cfg->min_pose_detection_confidence;
  options.min_pose_presence_confidence = cfg->min_pose_presence_confidence;
  options.min_tracking_confidence = cfg->min_tracking_confidence;
  options.output_segmentation_masks = cfg->output_segmentation_mask != 0;

  char* error_msg = nullptr;
  void* landmarker = PoseLandmarkerCreate(&options, &error_msg);
  if (!landmarker) {
    g_last_error_msg = error_msg ? error_msg : "Failed to create MediaPipe landmarker instance.";
    if (error_msg) free(error_msg);
    free(ctx);
    return MP_ERR_BACKEND;
  }
  ctx->landmarker_instance = landmarker;
#endif

  *out_handle = (mp_pose_handle)ctx;
  return MP_OK;
}

void MP_POSE_CALL mp_pose_destroy(mp_pose_handle h) {
  if (!h) return;
  mp_pose_context* ctx = (mp_pose_context*)h;

#ifdef MP_BRIDGE_BACKEND_REAL
  if (ctx->landmarker_instance) {
    PoseLandmarkerClose(ctx->landmarker_instance, nullptr);
  }
#endif

  free(ctx);
}

int32_t MP_POSE_CALL mp_pose_detect(mp_pose_handle h, const mp_image_raw* img, mp_pose_result** out_result) {
  if (!h || !img || !out_result) {
    g_last_error_msg = "Null parameter passed to mp_pose_detect.";
    return MP_ERR_BAD_ARG;
  }

  mp_pose_context* ctx = (mp_pose_context*)h;

  if (img->struct_size < (int32_t)sizeof(mp_image_raw)) {
    ctx->last_error = "Invalid mp_image_raw struct size.";
    return MP_ERR_ABI_MISMATCH;
  }

  if (!img->data) {
    ctx->last_error = "Image buffer data is null.";
    return MP_ERR_BAD_ARG;
  }

  if (img->channels != 3 && img->channels != 4) {
    ctx->last_error = "Unsupported channel count (only 3 or 4 channels are supported).";
    return MP_ERR_UNSUPPORTED;
  }

  if (img->stride < img->width * img->channels) {
    ctx->last_error = "Invalid image stride.";
    return MP_ERR_BAD_ARG;
  }

  if (ctx->config.running_mode == 1) { // Video mode
    // Validate monotonic timestamps (e.g. timestamp_ms must be >= previous)
  }

  // Allocate result container
  mp_pose_result* res = (mp_pose_result*)calloc(1, sizeof(mp_pose_result));
  if (!res) {
    ctx->last_error = "Failed to allocate memory for result structure.";
    return MP_ERR_OUT_OF_MEMORY;
  }

  res->struct_size = sizeof(mp_pose_result);
  res->landmarks_per_pose = MP_POSE_LANDMARK_COUNT;
  res->pose_count = ctx->config.num_poses > 0 ? ctx->config.num_poses : 1;
  if (res->pose_count > 4) res->pose_count = 4; // cap at 4 max for mockup safety

  // Allocate landmarks arrays
  res->landmarks = (mp_landmark*)calloc(res->pose_count * MP_POSE_LANDMARK_COUNT, sizeof(mp_landmark));
  res->world_landmarks = (mp_world_landmark*)calloc(res->pose_count * MP_POSE_LANDMARK_COUNT, sizeof(mp_world_landmark));

  if (!res->landmarks || !res->world_landmarks) {
    mp_pose_free_result(res);
    ctx->last_error = "Failed to allocate memory for result landmarks arrays.";
    return MP_ERR_OUT_OF_MEMORY;
  }

#ifdef MP_BRIDGE_BACKEND_REAL
  MpImage mp_img = {};
  mp_img.type = MpImageFormatRgb; // default format
  if (img->channels == 4) {
    mp_img.type = MpImageFormatRgba;
  }
  mp_img.width = img->width;
  mp_img.height = img->height;
  mp_img.data = img->data;

  PoseLandmarkerResult mp_res = {};
  char* error_msg = nullptr;
  int32_t status;

  if (ctx->config.running_mode == 1) {
    status = PoseLandmarkerDetectVideo(ctx->landmarker_instance, &mp_img, img->timestamp_ms, &mp_res, &error_msg);
  } else {
    status = PoseLandmarkerDetect(ctx->landmarker_instance, &mp_img, &mp_res, &error_msg);
  }

  if (status != 0) {
    mp_pose_free_result(res);
    ctx->last_error = error_msg ? error_msg : "MediaPipe native inference failed.";
    if (error_msg) free(error_msg);
    return MP_ERR_INFERENCE;
  }

  res->pose_count = mp_res.pose_landmarks_count;
  // Map coordinates
  for (int p = 0; p < res->pose_count; ++p) {
    for (int i = 0; i < MP_POSE_LANDMARK_COUNT; ++i) {
      int idx = p * MP_POSE_LANDMARK_COUNT + i;
      res->landmarks[idx].x = mp_res.pose_landmarks[p].landmarks[i].x;
      res->landmarks[idx].y = mp_res.pose_landmarks[p].landmarks[i].y;
      res->landmarks[idx].z = mp_res.pose_landmarks[p].landmarks[i].z;
      res->landmarks[idx].visibility = mp_res.pose_landmarks[p].landmarks[i].visibility;
      res->landmarks[idx].presence = mp_res.pose_landmarks[p].landmarks[i].presence;

      res->world_landmarks[idx].x = mp_res.pose_world_landmarks[p].landmarks[i].x;
      res->world_landmarks[idx].y = mp_res.pose_world_landmarks[p].landmarks[i].y;
      res->world_landmarks[idx].z = mp_res.pose_world_landmarks[p].landmarks[i].z;
    }
  }

  if (ctx->config.output_segmentation_mask && mp_res.segmentation_masks_count > 0) {
    res->mask_present = 1;
    res->mask_width = img->width;
    res->mask_height = img->height;
    res->mask = (uint8_t*)malloc(img->width * img->height);
    if (res->mask) {
      // Copy real segmentation mask data if available
      memcpy(res->mask, mp_res.segmentation_masks[0].data, img->width * img->height);
    }
  } else {
    res->mask_present = 0;
    res->mask = nullptr;
  }

  PoseLandmarkerResultFree(&mp_res);
#else
  // Mockup Stub Simulation (moving wave for verification without SDK)
  for (int p = 0; p < res->pose_count; ++p) {
    for (int i = 0; i < MP_POSE_LANDMARK_COUNT; ++i) {
      int idx = p * MP_POSE_LANDMARK_COUNT + i;
      // Normal landmarks [0..1]
      res->landmarks[idx].x = 0.5f + 0.12f * sinf(static_cast<float>(i) * 0.5f + static_cast<float>(p));
      res->landmarks[idx].y = 0.15f + 0.024f * static_cast<float>(i);
      res->landmarks[idx].z = 0.0f;
      res->landmarks[idx].visibility = 0.99f;
      res->landmarks[idx].presence = 0.99f;

      // World landmarks (in meters)
      res->world_landmarks[idx].x = 0.2f * sinf(static_cast<float>(i) * 0.5f);
      res->world_landmarks[idx].y = -0.5f + 0.05f * static_cast<float>(i);
      res->world_landmarks[idx].z = -0.1f * static_cast<float>(i);
    }
  }

  if (ctx->config.output_segmentation_mask) {
    res->mask_present = 1;
    res->mask_width = img->width;
    res->mask_height = img->height;
    res->mask = (uint8_t*)malloc(img->width * img->height);
    if (res->mask) {
      // Create a dummy silhouette mask
      memset((void*)res->mask, 128, img->width * img->height);
    }
  } else {
    res->mask_present = 0;
    res->mask = nullptr;
  }
#endif

  *out_result = res;
  return MP_OK;
}

void MP_POSE_CALL mp_pose_free_result(mp_pose_result* result) {
  if (!result) return;

  if (result->landmarks) {
    free(result->landmarks);
  }
  if (result->world_landmarks) {
    free(result->world_landmarks);
  }
  if (result->mask) {
    free((void*)result->mask);
  }
  free(result);
}

const char* MP_POSE_CALL mp_pose_last_error(mp_pose_handle h) {
  if (!h) {
    return g_last_error_msg.c_str();
  }
  mp_pose_context* ctx = (mp_pose_context*)h;
  return ctx->last_error.c_str();
}

}

