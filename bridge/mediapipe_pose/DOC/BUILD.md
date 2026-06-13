# Compilation Guide

This guide details how to build the dynamic bridge library (`mp_pose_bridge.dll` or `libmp_pose_bridge.so`) from source.

## 1. Prerequisites

Ensure you have the following toolchains installed:
- **CMake** (version 3.16+)
- **Bazel** (or Bazelisk) matching the version requested by Google MediaPipe
- Compiler:
  - Windows: **MSVC** (Visual Studio 2019 or newer)
  - Linux: **GCC** (version 9+)
- **Git** with Git LFS support

## 2. Bazel Dependency Setup

The bridge communicates with the MediaPipe Tasks C API. You need to pull the MediaPipe source code:
```bash
git submodule init
git submodule update
```

Or configure the `WORKSPACE` file in `build/` to download it automatically:
```bazel
# Example pin
git_repository(
    name = "mediapipe",
    remote = "https://github.com/google-ai-edge/mediapipe.git",
    commit = "0.10.35",
)
```

## 3. Build Steps (CMake)

### Windows x64
To build on Windows using MSVC:
```cmd
mkdir build_win
cd build_win
cmake -G "Visual Studio 16 2019" -A x64 -DMP_POSE_BUILD=ON ..
cmake --build . --config Release
```
This produces `mp_pose_bridge.dll` in the output directory.

### Linux x64
To build on Linux:
```bash
mkdir build_linux
cd build_linux
cmake -DCMAKE_BUILD_TYPE=Release -DMP_POSE_BUILD=ON ..
make -j$(nproc)
```
This produces `libmp_pose_bridge.so`.

## 4. Static Linkage Configuration
To make the library auto-contained and avoid dependencies on C/C++ runtimes:
- Windows: Build with static runtime (`/MT` flag in CMake).
- Linux: Link statically to libgcc and libstdc++:
  ```cmake
  target_link_options(mp_pose_bridge PRIVATE -static-libstdc++ -static-libgcc -Wl,--exclude-libs,ALL)
  ```

## 5. Backend Configuration Flag (MP_BRIDGE_BACKEND)

When generating build files with CMake, you can configure the backend target:
- `-DMP_BRIDGE_BACKEND=SIM` (default): builds the bridge using simulation mock logic, resolving compilation without Bazel.
- `-DMP_BRIDGE_BACKEND=REAL`: links and integrates with the MediaPipe Tasks C API framework.

Example configuration command:
```bash
cmake -DMP_BRIDGE_BACKEND=REAL -DMP_POSE_BUILD=ON ..
```

