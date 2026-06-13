# Compilation Guide

This guide details how to build the dynamic bridge library (`ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll` on Windows or `libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so` on Linux) from source.

## 1. Prerequisites

Ensure you have the following toolchains installed:
- CMake 3.16 or newer
- Bazel or Bazelisk matching the MediaPipe requirement
- A C/C++ compiler:
  - Windows: MSVC 2019 or newer
  - Linux: GCC 9 or newer
- Git with Git LFS support

## 2. Bazel Dependency Setup

The bridge communicates with the MediaPipe Tasks C API. Pull the MediaPipe source tree first:

```bash
git submodule init
git submodule update
```

Or configure the `WORKSPACE` file in `build/` to download it automatically:

```bazel
git_repository(
    name = "mediapipe",
    remote = "https://github.com/google-ai-edge/mediapipe.git",
    commit = "0.10.35",
)
```

## 3. Build Steps (CMake)

For day-to-day work, the repository now includes two helper scripts:
- `tools/build_sim.ps1` -> configures and builds the SIM backend in `build/build_sim`.
- `tools/build_real.ps1` -> configures and builds the REAL backend in `build/build_real`.
- Both scripts also sync the official runtime tree under `runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/`.

### Windows x64

```cmd
cmake -S bridge/mediapipe_pose/build -B bridge/mediapipe_pose/build/build_sim -DMP_POSE_BUILD=ON -DMP_BRIDGE_BACKEND=SIM
cmake --build bridge/mediapipe_pose/build/build_sim --config Release
```

This produces `ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll`.

### Linux x64

```bash
cmake -S bridge/mediapipe_pose/build -B bridge/mediapipe_pose/build/build_linux -DCMAKE_BUILD_TYPE=Release -DMP_POSE_BUILD=ON
cmake --build bridge/mediapipe_pose/build/build_linux --parallel
```

This produces `libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so`.

## 4. Static Linkage Configuration

To make the library auto-contained and avoid dependencies on C/C++ runtimes:
- Windows: build with the static runtime (`/MT`).
- Linux: link statically to libgcc and libstdc++:

```cmake
target_link_options(mp_pose_bridge PRIVATE -static-libstdc++ -static-libgcc -Wl,--exclude-libs,ALL)
```

## 5. Backend Configuration Flag (MP_BRIDGE_BACKEND)

Use the CMake flag below to choose the execution backend:
- `-DMP_BRIDGE_BACKEND=SIM` (default): simulated backend, no Bazel or MediaPipe runtime required. This is the validated runtime path for the versioned bridge binary.
- `-DMP_BRIDGE_BACKEND=REAL`: integrates the MediaPipe Tasks C API. This path is still experimental and requires the `.task` model files, TensorFlow Lite, and the MediaPipe native dependencies.

Example:

```bash
cmake -DMP_BRIDGE_BACKEND=SIM -DMP_POSE_BUILD=ON ..
```

## 6. Legacy Compatibility

The loader still accepts `mp_pose_bridge.dll` and `libmp_pose_bridge.so` as legacy fallbacks, but the official runtime filenames are the versioned ones above.
