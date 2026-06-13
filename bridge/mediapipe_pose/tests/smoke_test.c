#include "../include/mp_pose_bridge.h"
#include <stdio.h>
#include <stdlib.h>

#if defined(_WIN32)
  #include <windows.h>
  typedef HMODULE LibHandle;
  #define LoadLib(path) LoadLibraryA(path)
  #define GetSym(handle, name) GetProcAddress(handle, name)
  #define CloseLib(handle) FreeLibrary(handle)
  #define LIB_NAME "mp_pose_bridge.dll"
#else
  #include <dlfcn.h>
  typedef void* LibHandle;
  #define LoadLib(path) dlopen(path, RTLD_LAZY)
  #define GetSym(handle, name) dlsym(handle, name)
  #define CloseLib(handle) dlclose(handle)
  #define LIB_NAME "./libmp_pose_bridge.so"
#endif

typedef int32_t (MP_POSE_CALL *TFunc_mp_pose_get_info)(mp_pose_info* out_info);
typedef int32_t (MP_POSE_CALL *TFunc_mp_pose_create)(const mp_pose_config* cfg, mp_pose_handle* out_handle);
typedef void    (MP_POSE_CALL *TFunc_mp_pose_destroy)(mp_pose_handle h);
typedef int32_t (MP_POSE_CALL *TFunc_mp_pose_detect)(mp_pose_handle h, const mp_image_raw* img, mp_pose_result** out_result);
typedef void    (MP_POSE_CALL *TFunc_mp_pose_free_result)(mp_pose_result** result);
typedef const char* (MP_POSE_CALL *TFunc_mp_pose_last_error)(mp_pose_handle h);

int main() {
    printf("Starting C Smoke Test...\n");

    LibHandle lib = LoadLib(LIB_NAME);
    if (!lib) {
        printf("FAILED: Could not load dynamic library %s\n", LIB_NAME);
        return 1;
    }

    TFunc_mp_pose_get_info p_mp_pose_get_info = (TFunc_mp_pose_get_info)GetSym(lib, "mp_pose_get_info");
    TFunc_mp_pose_create p_mp_pose_create = (TFunc_mp_pose_create)GetSym(lib, "mp_pose_create");
    TFunc_mp_pose_destroy p_mp_pose_destroy = (TFunc_mp_pose_destroy)GetSym(lib, "mp_pose_destroy");
    TFunc_mp_pose_detect p_mp_pose_detect = (TFunc_mp_pose_detect)GetSym(lib, "mp_pose_detect");
    TFunc_mp_pose_free_result p_mp_pose_free_result = (TFunc_mp_pose_free_result)GetSym(lib, "mp_pose_free_result");
    TFunc_mp_pose_last_error p_mp_pose_last_error = (TFunc_mp_pose_last_error)GetSym(lib, "mp_pose_last_error");

    if (!p_mp_pose_get_info || !p_mp_pose_create || !p_mp_pose_destroy || 
        !p_mp_pose_detect || !p_mp_pose_free_result || !p_mp_pose_last_error) {
        printf("FAILED: One or more exports were not found in the library.\n");
        CloseLib(lib);
        return 1;
    }

    // Test 1: Get Info
    mp_pose_info info;
    info.struct_size = sizeof(mp_pose_info);
    int32_t status = p_mp_pose_get_info(&info);
    if (status != MP_OK) {
        printf("FAILED: mp_pose_get_info returned error code %d\n", status);
        CloseLib(lib);
        return 1;
    }

    printf("Library Info:\n");
    printf("  ABI Version: %d (Expected: %d)\n", info.abi_version, MP_POSE_ABI_VERSION);
    printf("  Bridge Version: %s\n", info.bridge_version);
    printf("  MediaPipe Version: %s\n", info.mediapipe_version);
    printf("  Platform: %s\n", info.platform);
    printf("  Arch: %s\n", info.arch);

    if (info.abi_version != MP_POSE_ABI_VERSION) {
        printf("FAILED: ABI version mismatch!\n");
        CloseLib(lib);
        return 1;
    }

    // Test 2: Create Detector Instance
    mp_pose_config cfg;
    cfg.struct_size = sizeof(mp_pose_config);
    cfg.model_path = "models/pose_landmarker_full.task";
    cfg.running_mode = 0; // IMAGE
    cfg.num_poses = 1;
    cfg.min_pose_detection_confidence = 0.5f;
    cfg.min_pose_presence_confidence = 0.5f;
    cfg.min_tracking_confidence = 0.5f;
    cfg.output_segmentation_mask = 1;
    cfg.num_threads = 0;

    mp_pose_handle handle = NULL;
    status = p_mp_pose_create(&cfg, &handle);
    if (status != MP_OK || !handle) {
        printf("FAILED: mp_pose_create failed with code %d. Error: %s\n", status, p_mp_pose_last_error(NULL));
        CloseLib(lib);
        return 1;
    }
    printf("Successfully created MediaPipe pose detector handle.\n");

    // Test 3: Run Inference on Dummy Image
    uint8_t dummy_pixels[100 * 100 * 3] = {0}; // 100x100 RGB image
    mp_image_raw raw_img;
    raw_img.struct_size = sizeof(mp_image_raw);
    raw_img.data = dummy_pixels;
    raw_img.width = 100;
    raw_img.height = 100;
    raw_img.channels = 3;
    raw_img.stride = 100 * 3;
    raw_img.timestamp_ms = 0;

    mp_pose_result* result = NULL;
    status = p_mp_pose_detect(handle, &raw_img, &result);
    if (status != MP_OK || !result) {
        printf("FAILED: mp_pose_detect failed with code %d. Error: %s\n", status, p_mp_pose_last_error(handle));
        p_mp_pose_destroy(handle);
        CloseLib(lib);
        return 1;
    }

    printf("Inference succeeded:\n");
    printf("  Poses found: %d\n", result->pose_count);
    printf("  Landmarks per pose: %d\n", result->landmarks_per_pose);

    if (result->pose_count > 0 && result->landmarks) {
        printf("  First Landmark (Nose): X=%f, Y=%f, Z=%f\n", 
               result->landmarks[0].x, result->landmarks[0].y, result->landmarks[0].z);
    }

    // Clean up
    p_mp_pose_free_result(&result);
    p_mp_pose_destroy(handle);
    CloseLib(lib);

    printf("C Smoke Test completed successfully!\n");
    return 0;
}
