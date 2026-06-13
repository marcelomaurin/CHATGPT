#include "../include/mp_pose_bridge.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <new>      /* std::nothrow */
#include <string>
#include <sstream>
#include <fstream>
#include <cstdio>
#include <memory>
#include <array>

/* -------------------------------------------------------------------------
 * Error channels (FASE5-02)
 *
 * Two distinct channels, never mixed:
 *   g_last_error_msg  — thread_local — for errors WITHOUT a context handle
 *                       (bad arg before create, allocation failure in create).
 *                       Returned by mp_pose_last_error(NULL).
 *   ctx->last_error   — std::string on the context — for errors WITH a valid
 *                       handle (inference failure, bad image, etc.).
 *                       Returned by mp_pose_last_error(handle).
 * ------------------------------------------------------------------------- */
#ifdef _MSC_VER
  #define THREAD_LOCAL __declspec(thread)
#else
  #define THREAD_LOCAL thread_local
#endif

static THREAD_LOCAL std::string g_last_error_msg = "";

/* -------------------------------------------------------------------------
 * mp_pose_context
 * Contains std::string → must be allocated with new/delete so that
 * constructors and destructors run correctly.  (calloc/free is UB here.)
 * mp_pose_result stays POD → malloc/free, preserving free_result symmetry.
 * ------------------------------------------------------------------------- */
struct mp_pose_context {
  mp_pose_config config;
  std::string    last_error;
  void*          landmarker_instance; /* unused, kept for ABI layout compatibility */
};

// Subprocess execution helper
static std::string exec_cmd(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
#ifdef _WIN32
    std::unique_ptr<FILE, decltype(&_pclose)> pipe(_popen(cmd, "r"), _pclose);
#else
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
#endif
    if (!pipe) {
        return "";
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

extern "C" {

/* =========================================================================
 * mp_pose_create
 * ========================================================================= */
int32_t MP_POSE_CALL mp_pose_create(const mp_pose_config* cfg, mp_pose_handle* out_handle) {
  if (!cfg || !out_handle) {
    g_last_error_msg = "Null configuration or output handle pointer.";
    return MP_ERR_BAD_ARG;
  }

  if (cfg->struct_size < (int32_t)sizeof(mp_pose_config)) {
    g_last_error_msg = "Invalid mp_pose_config struct size (ABI mismatch).";
    return MP_ERR_ABI_MISMATCH;
  }

#ifdef MP_BRIDGE_BACKEND_REAL
  /* REAL backend: model_path is mandatory */
  if (!cfg->model_path || strlen(cfg->model_path) == 0) {
    g_last_error_msg = "Model path cannot be empty (backend REAL requires a .task file).";
    return MP_ERR_MODEL_LOAD;
  }
  FILE* f = fopen(cfg->model_path, "rb");
  if (!f) {
    g_last_error_msg = "Failed to open model file: " + std::string(cfg->model_path);
    return MP_ERR_MODEL_LOAD;
  }
  fclose(f);
#endif
  /* SIM backend: model_path is optional and silently ignored */

  /* Use new(std::nothrow) so that std::string in the context is properly
   * constructed.  calloc would leave the std::string in an invalid state. */
  mp_pose_context* ctx = new (std::nothrow) mp_pose_context();
  if (!ctx) {
    g_last_error_msg = "Failed to allocate memory for context.";
    return MP_ERR_OUT_OF_MEMORY;
  }

  ctx->config = *cfg;
  ctx->landmarker_instance = nullptr;

  *out_handle = static_cast<mp_pose_handle>(ctx);
  return MP_OK;
}

/* =========================================================================
 * mp_pose_destroy
 * ========================================================================= */
void MP_POSE_CALL mp_pose_destroy(mp_pose_handle h) {
  if (!h) return;
  mp_pose_context* ctx = static_cast<mp_pose_context*>(h);
  delete ctx;   /* delete runs ~mp_pose_context() → ~std::string() */
}

/* =========================================================================
 * mp_pose_detect
 * ========================================================================= */
int32_t MP_POSE_CALL mp_pose_detect(mp_pose_handle h, const mp_image_raw* img, mp_pose_result** out_result) {
  if (!h || !img || !out_result) {
    g_last_error_msg = "Null parameter passed to mp_pose_detect.";
    return MP_ERR_BAD_ARG;
  }

  mp_pose_context* ctx = static_cast<mp_pose_context*>(h);

  if (img->struct_size < (int32_t)sizeof(mp_image_raw)) {
    ctx->last_error = "Invalid mp_image_raw struct size (ABI mismatch).";
    return MP_ERR_ABI_MISMATCH;
  }

  if (!img->data) {
    ctx->last_error = "Image buffer data is null.";
    return MP_ERR_BAD_ARG;
  }

  if (img->channels != 3 && img->channels != 4) {
    ctx->last_error = "Unsupported channel count (only 3 or 4 are supported).";
    return MP_ERR_UNSUPPORTED;
  }

  if (img->stride < img->width * img->channels) {
    ctx->last_error = "Invalid image stride (stride < width * channels).";
    return MP_ERR_BAD_ARG;
  }

  /* Allocate result container (POD — malloc/free) */
  mp_pose_result* res = static_cast<mp_pose_result*>(calloc(1, sizeof(mp_pose_result)));
  if (!res) {
    ctx->last_error = "Failed to allocate memory for result structure.";
    return MP_ERR_OUT_OF_MEMORY;
  }

  res->struct_size       = sizeof(mp_pose_result);
  res->landmarks_per_pose = MP_POSE_LANDMARK_COUNT;
  res->pose_count         = 0;
  res->landmarks          = nullptr;
  res->world_landmarks    = nullptr;

#ifdef MP_BRIDGE_BACKEND_REAL
  // 1. Generate temp file path using TEMP environment variable
  const char* temp_env = getenv("TEMP");
  if (!temp_env) temp_env = getenv("TMP");
  if (!temp_env) temp_env = ".";

  std::string temp_file = std::string(temp_env) + "/mp_pose_input_" + std::to_string(rand()) + ".raw";

  // 2. Write image data to the raw file
  std::ofstream out(temp_file, std::ios::binary);
  if (!out) {
    ctx->last_error = "Failed to open temp file for writing: " + temp_file;
    mp_pose_free_result(&res);
    return MP_ERR_BACKEND;
  }

  int32_t width_val = img->width;
  int32_t height_val = img->height;
  out.write(reinterpret_cast<const char*>(&width_val), 4);
  out.write(reinterpret_cast<const char*>(&height_val), 4);

  // Write 3-channel RGB raw pixels (convert from 4-channels if necessary)
  const uint8_t* row_data = img->data;
  for (int y = 0; y < height_val; ++y) {
    const uint8_t* pixel = row_data;
    for (int x = 0; x < width_val; ++x) {
      if (img->channels == 3) {
        out.write(reinterpret_cast<const char*>(pixel), 3);
        pixel += 3;
      } else if (img->channels == 4) {
        out.write(reinterpret_cast<const char*>(pixel), 3);
        pixel += 4;
      }
    }
    row_data += img->stride;
  }
  out.close();

  // 3. Resolve the path to pose_worker.py relative to model_path
  std::string model_path = ctx->config.model_path;
  std::string python_script = "";
  size_t pos = model_path.find("runtime");
  if (pos != std::string::npos) {
    python_script = model_path.substr(0, pos) + "runtime\\mediapipe\\pose\\pose_worker.py";
  } else {
    python_script = "D:\\projetos\\maurinsoft\\CHATGPT\\runtime\\mediapipe\\pose\\pose_worker.py";
  }

  // 4. Build and execute command: python "pose_worker.py" "model_path" "temp_file"
  std::string cmd = "python \"" + python_script + "\" \"" + model_path + "\" \"" + temp_file + "\"";
  std::string output = exec_cmd(cmd.c_str());

  // Clean up the temporary file immediately
  std::remove(temp_file.c_str());

  // 5. Parse Python worker stdout
  std::stringstream ss(output);
  std::string line;
  int current_pose = -1;
  int current_landmark = 0;

  while (std::getline(ss, line)) {
    if (line.rfind("POSES:", 0) == 0) {
      int p_count = std::stoi(line.substr(6));
      res->pose_count = p_count;
      if (res->pose_count > 4) res->pose_count = 4;
      if (res->pose_count > 0) {
        res->landmarks = static_cast<mp_landmark*>(
            calloc(res->pose_count * MP_POSE_LANDMARK_COUNT, sizeof(mp_landmark)));
        res->world_landmarks = static_cast<mp_world_landmark*>(
            calloc(res->pose_count * MP_POSE_LANDMARK_COUNT, sizeof(mp_world_landmark)));
        if (!res->landmarks || !res->world_landmarks) {
          mp_pose_free_result(&res);
          ctx->last_error = "Failed to allocate landmark arrays.";
          return MP_ERR_OUT_OF_MEMORY;
        }
      }
    } else if (line.rfind("POSE:", 0) == 0) {
      current_pose = std::stoi(line.substr(5));
      current_landmark = 0;
    } else if (current_pose >= 0 && current_pose < res->pose_count) {
      std::stringstream line_ss(line);
      float lx, ly, lz, vis, pres, wx, wy, wz;
      if (line_ss >> lx >> ly >> lz >> vis >> pres >> wx >> wy >> wz) {
        if (current_landmark < MP_POSE_LANDMARK_COUNT) {
          int idx = current_pose * MP_POSE_LANDMARK_COUNT + current_landmark;
          res->landmarks[idx].x = lx;
          res->landmarks[idx].y = ly;
          res->landmarks[idx].z = lz;
          res->landmarks[idx].visibility = vis;
          res->landmarks[idx].presence = pres;

          res->world_landmarks[idx].x = wx;
          res->world_landmarks[idx].y = wy;
          res->world_landmarks[idx].z = wz;
          current_landmark++;
        }
      }
    } else if (line.rfind("ERROR:", 0) == 0) {
      ctx->last_error = line.substr(6);
      mp_pose_free_result(&res);
      return MP_ERR_INFERENCE;
    }
  }

  res->mask_present = 0;
  res->mask = nullptr;

#else  /* SIM */

  /* SIM backend returns 0 poses (no simulated points) */
  res->mask_present = 0;
  res->mask = nullptr;
#endif

  *out_result = res;
  return MP_OK;
}

/* =========================================================================
 * mp_pose_free_result
 * Double-pointer signature: sets *result to NULL after freeing.
 * mp_pose_result is POD → malloc/free throughout.
 * ========================================================================= */
void MP_POSE_CALL mp_pose_free_result(mp_pose_result** result) {
  if (!result || !*result) return;

  mp_pose_result* res = *result;

  if (res->landmarks)       free(res->landmarks);
  if (res->world_landmarks) free(res->world_landmarks);
  if (res->mask)            free(const_cast<uint8_t*>(res->mask));

  free(res);
  *result = nullptr;
}

/* =========================================================================
 * mp_pose_last_error
 * h == NULL  → global channel (g_last_error_msg)
 * h != NULL  → context channel (ctx->last_error)
 * ========================================================================= */
const char* MP_POSE_CALL mp_pose_last_error(mp_pose_handle h) {
  if (!h) return g_last_error_msg.c_str();
  return static_cast<mp_pose_context*>(h)->last_error.c_str();
}

} /* extern "C" */
