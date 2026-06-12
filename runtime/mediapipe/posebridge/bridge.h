#ifndef BRIDGE_H
#define BRIDGE_H

#ifdef _WIN32
  #define DLL_EXPORT __declspec(dllexport)
#else
  #define DLL_EXPORT __attribute__((visibility("default")))
#endif

// ============================================================================
// AI MediaPipe Pose Bridge - C++ Headers
// ABI interfaces exposing C functions with cdecl calling convention.
// ============================================================================

extern "C" {

DLL_EXPORT int InitMPPose(
    const char* AModelPath,
    int AMaxPoses,
    float AMinDetectConfidence,
    float AMinPresenceConfidence,
    float AMinTrackingConfidence,
    unsigned char AOutputMasks
);

DLL_EXPORT int DetectMPPoseFrame(
    void* APixels,
    int AWidth,
    int AHeight,
    int AFormat,
    float* AOutScore,
    float* AOutLandmarks,
    void* AOutMaskPixels
);

DLL_EXPORT void CloseMPPose();

}

#endif // BRIDGE_H
