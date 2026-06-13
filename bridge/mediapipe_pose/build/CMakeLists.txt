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

# Compile definitions
target_compile_definitions(mp_pose_bridge PRIVATE
    MP_POSE_BUILD
)

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
