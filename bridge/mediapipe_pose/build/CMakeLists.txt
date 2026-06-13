cmake_minimum_required(VERSION 3.16)
project(mp_pose_bridge LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define library target
add_library(mp_pose_bridge SHARED
    ../src/mp_pose_info.cpp
    ../src/mp_pose_bridge.cpp
)

# Include directories
target_include_directories(mp_pose_bridge PRIVATE
    ../include
)

# Backend selection: SIM (simulated) or REAL (MediaPipe integration)
set(MP_BRIDGE_BACKEND "SIM" CACHE STRING "Execution backend: SIM or REAL")
set_property(CACHE MP_BRIDGE_BACKEND PROPERTY STRINGS "SIM" "REAL")

if(NOT MP_BRIDGE_BACKEND STREQUAL "SIM" AND NOT MP_BRIDGE_BACKEND STREQUAL "REAL")
    message(FATAL_ERROR "Invalid MP_BRIDGE_BACKEND value: '${MP_BRIDGE_BACKEND}'. Must be SIM or REAL.")
endif()

# Compile definitions
target_compile_definitions(mp_pose_bridge PRIVATE
    MP_POSE_BUILD
)

if(MP_BRIDGE_BACKEND STREQUAL "REAL")
    message(WARNING "REAL MediaPipe backend selected. Bazel / MediaPipe C API configuration is required for compilation.")
    target_compile_definitions(mp_pose_bridge PRIVATE MP_BRIDGE_BACKEND_REAL)
else()
    target_compile_definitions(mp_pose_bridge PRIVATE MP_BRIDGE_BACKEND_SIM)
endif()

# Configure output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Target configurations depending on Platform
if(WIN32)
    # Enable static runtime (/MT or /MTd)
    set_property(TARGET mp_pose_bridge PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    
    # Export definition file
    target_link_options(mp_pose_bridge PRIVATE "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/mp_pose_bridge.def")
else()
    # Linux-specific static linkages to prevent dynamic runtime dependency issues
    target_link_options(mp_pose_bridge PRIVATE 
        "-static-libstdc++"
        "-static-libgcc"
        "-Wl,--exclude-libs,ALL"
        "-Wl,--version-script,${CMAKE_CURRENT_SOURCE_DIR}/mp_pose_bridge.map"
    )
endif()
