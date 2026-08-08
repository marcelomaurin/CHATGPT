cmake_minimum_required(VERSION 3.20)

project(chatgpt_llama_bridge LANGUAGES CXX)

set(LLAMA_CPP_SOURCE_DIR "" CACHE PATH
    "Path to the pinned llama.cpp source tree (b5200)")

if(NOT WIN32)
    message(FATAL_ERROR "chatgpt_llama_bridge currently supports Windows only")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "chatgpt_llama_bridge must be built for x64")
endif()

if(NOT EXISTS "${LLAMA_CPP_SOURCE_DIR}/include/llama.h")
    message(FATAL_ERROR
        "LLAMA_CPP_SOURCE_DIR must point to the pinned llama.cpp b5200 source tree")
endif()

set(BUILD_SHARED_LIBS ON CACHE BOOL "Build llama.cpp shared libraries" FORCE)
set(LLAMA_BUILD_COMMON OFF CACHE BOOL "Do not build llama.cpp common helpers" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Do not build llama.cpp tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Do not build llama.cpp examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Do not build llama.cpp server" FORCE)
set(GGML_BUILD_TESTS OFF CACHE BOOL "Do not build ggml tests" FORCE)
set(GGML_BUILD_EXAMPLES OFF CACHE BOOL "Do not build ggml examples" FORCE)

add_subdirectory(
    "${LLAMA_CPP_SOURCE_DIR}"
    "${CMAKE_BINARY_DIR}/llama.cpp"
    EXCLUDE_FROM_ALL
)

add_library(chatgpt_llama_bridge SHARED
    chatgpt_llama_bridge.cpp
    chatgpt_llama_bridge.h
)

target_compile_features(chatgpt_llama_bridge PRIVATE cxx_std_17)
target_compile_definitions(chatgpt_llama_bridge
    PRIVATE CHATGPT_LLAMA_BRIDGE_EXPORTS
)
target_link_libraries(chatgpt_llama_bridge PRIVATE llama)

set_target_properties(chatgpt_llama_bridge PROPERTIES
    PREFIX ""
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
