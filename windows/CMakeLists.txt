cmake_minimum_required(VERSION 3.14)
project(muna_library VERSION 0.0.1)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64")
    set(ARCH "arm64")
else()
    set(ARCH "x86_64")
endif()

set(muna_bundled_libraries
    "${CMAKE_CURRENT_SOURCE_DIR}/${ARCH}/Function.dll"
    PARENT_SCOPE
)