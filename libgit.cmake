# ========== EMBEDDED LIBGIT2 SETUP ==========

set(LIBGIT2_ROOT "${THIRD_PARTY_DIR}/libgit2_mingw")
set(LIBGIT2_INCLUDE_DIR "${LIBGIT2_ROOT}/include")
set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/libgit2.a")

if(NOT EXISTS "${LIBGIT2_INCLUDE_DIR}/git2.h")
    message(FATAL_ERROR "git2.h not found at ${LIBGIT2_INCLUDE_DIR}")
endif()

if(NOT EXISTS "${LIBGIT2_LIBRARY}")
    message(FATAL_ERROR "libgit2.a not found at ${LIBGIT2_LIBRARY}")
endif()

add_library(libgit2 STATIC IMPORTED GLOBAL)

set_target_properties(libgit2 PROPERTIES
    IMPORTED_LOCATION "${LIBGIT2_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBGIT2_INCLUDE_DIR}"
)

message(STATUS "Using embedded libgit2:")
message(STATUS "  Include: ${LIBGIT2_INCLUDE_DIR}")
message(STATUS "  Library: ${LIBGIT2_LIBRARY}")

# MinGW static libgit2 dependencies
if (MINGW)
    target_link_libraries(libgit2 INTERFACE
        ws2_32
        bcrypt
        crypt32
        secur32
        rpcrt4
        winhttp
        z
    )
endif()

# ========== END LIBGIT2 SETUP ==========
